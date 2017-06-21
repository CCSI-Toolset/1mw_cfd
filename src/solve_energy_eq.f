!vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvC
!                                                                      C
!  Subroutine: SOLVE_ENERGY_EQ                                         C
!  Purpose: Solve energy equations                                     C
!                                                                      C
!                                                                      C
!  Author: M. Syamlal                                 Date: 29-APR-97  C
!  Reviewer:                                          Date:            C
!                                                                      C
!  Revision Number: 1                                                  C
!  Purpose: Eliminate energy calculations when doing DEM               C
!  Author: Jay Boyalakuntla                           Date: 12-Jun-04  C
!                                                                      C
!  Literature/Document References:                                     C
!                                                                      C
!  Variables referenced:                                               C
!  Variables modified:                                                 C
!  Local variables:                                                    C
!                                                                      C
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^C

      SUBROUTINE SOLVE_ENERGY_EQ(IER) 

!-----------------------------------------------
! Modules
!-----------------------------------------------
      USE param 
      USE param1 
      USE toleranc 
      USE run
      USE physprop
      USE geometry
      USE fldvar
      USE output
      USE indices
      USE drag
      USE residual
      USE ur_facs 
      USE pgcor
      USE pscor
      USE leqsol 
      USE bc
      USE energy
      USE rxns
      Use ambm
      Use tmp_array, S_p => ARRAY1, S_C => ARRAY2, EPs => ARRAY3
      Use tmp_array1, VxGama => ARRAYm1
      USE compar   
      USE discretelement 
      USE des_thermo
      USE mflux     
      USE mpi_utility      
      USE sendrecv 
      USE ps
      USE mms
      USE ic  ! Cyl-subgrid model keywords - WAL 10/2014
      USE constant

      IMPLICIT NONE
!-----------------------------------------------
! Dummy arguments
!-----------------------------------------------
! Error index 
      INTEGER, INTENT(INOUT) :: IER 
!-----------------------------------------------
! Local variables
!-----------------------------------------------
! phase index 
      INTEGER :: M 
      INTEGER :: TMP_SMAX
!  Cp * Flux 
      DOUBLE PRECISION :: CpxFlux_E(DIMENSION_3), &
                          CpxFlux_N(DIMENSION_3), &
                          CpxFlux_T(DIMENSION_3) 
! previous time step term  
      DOUBLE PRECISION :: apo 
! Indices 
      INTEGER :: IJK, I, J, K 
! linear equation solver method and iterations 
      INTEGER :: LEQM, LEQI 

! Arrays for storing errors:
! 120 - Gas phase energy equation diverged
! 121 - Solids energy equation diverged
! 12x - Unclassified
      INTEGER :: Err_l(0:numPEs-1)  ! local
      INTEGER :: Err_g(0:numPEs-1)  ! global

! Cyl-subgrid model - WAL 10/2014
      DOUBLE PRECISION :: U_S_STAR, V_S_STAR
      DOUBLE PRECISION :: D_CYL_STAR, A_CYL_STAR
      DOUBLE PRECISION :: T_SUSP, Q_GSC
      DOUBLE PRECISION :: L_STAR, E_STAR
      DOUBLE PRECISION :: DT_STAR, H_GSC_STAR
      DOUBLE PRECISION :: H_limiter
      DOUBLE PRECISION, PARAMETER :: EPS_lim=5.0D-2

! temporary use of global arrays:
! arraym1 (locally vxgama) 
! the volume x average gas-solids heat transfer at cell centers
!      DOUBLE PRECISION :: VXGAMA(DIMENSION_3, DIMENSION_M)
! array1 (locally s_p) 
! source vector: coefficient of dependent variable
! becomes part of a_m matrix; must be positive      
!      DOUBLE PRECISION :: S_P(DIMENSION_3)
! array2 (locally s_c)
! source vector: constant part becomes part of b_m vector
!      DOUBLE PRECISION :: S_C(DIMENSION_3)
! array3 (locally eps)
!      DOUBLE PRECISION :: EPS(DIMENSION_3)      

! Septadiagonal matrix A_m, vector b_m
!      DOUBLE PRECISION A_m(DIMENSION_3, -3:3, 0:DIMENSION_M)
!      DOUBLE PRECISION B_m(DIMENSION_3, 0:DIMENSION_M)
!-----------------------------------------------
! Include statement functions      
!-----------------------------------------------
      INCLUDE 'radtn1.inc'
      INCLUDE 'ep_s1.inc'
      INCLUDE 'function.inc'
      INCLUDE 'ep_s2.inc'
      INCLUDE 'radtn2.inc'
!-----------------------------------------------

      call lock_ambm         ! locks arrys a_m and b_m
      call lock_tmp_array    ! locks arraym1 (locally vxgama) 
      call lock_tmp_array1   ! locks array1, array2, array3 
                             ! (locally s_p, s_c, eps) 
! Initialize error flags.
      Err_l = 0

      TMP_SMAX = SMAX
      IF(DISCRETE_ELEMENT) THEN
         TMP_SMAX = 0   ! Only the gas calculations are needed
      ENDIF            

! initializing      

! Cyl-subgrid model - WAL 10/2014
      IF (ANY_IC_SG) THEN
         TMP_SMAX = 1
      ENDIF

      DO M = 0, TMP_SMAX 
         CALL INIT_AB_M (A_M, B_M, IJKMAX2, M, IER) 
      ENDDO 

      DO IJK = IJKSTART3, IJKEND3
         I = I_OF(IJK)
         J = J_OF(IJK)
         K = K_OF(IJK) 

         IF (IS_ON_myPE_plus2layers(IP1(I),J,K)) THEN
            IF(.NOT.ADDED_MASS) THEN
               CpxFlux_E(IJK) = HALF * (C_pg(IJK) + C_pg(IP_OF(IJK))) * Flux_gE(IJK)
            ELSE
               CpxFlux_E(IJK) = HALF * (C_pg(IJK) + C_pg(IP_OF(IJK))) * Flux_gSE(IJK)
            ENDIF
         ENDIF
         
         IF (IS_ON_myPE_plus2layers(I,JP1(J),K)) THEN
            IF(.NOT.ADDED_MASS) THEN
               CpxFlux_N(IJK) = HALF * (C_pg(IJK) + C_pg(JP_OF(IJK))) * Flux_gN(IJK)
            ELSE
               CpxFlux_N(IJK) = HALF * (C_pg(IJK) + C_pg(JP_OF(IJK))) * Flux_gSN(IJK)
            ENDIF
         ENDIF
         
         IF (IS_ON_myPE_plus2layers(I,J,KP1(K))) THEN
            IF(.NOT.ADDED_MASS) THEN
               CpxFlux_T(IJK) = HALF * (C_pg(IJK) + C_pg(KP_OF(IJK))) * Flux_gT(IJK)
            ELSE
               CpxFlux_T(IJK) = HALF * (C_pg(IJK) + C_pg(KP_OF(IJK))) * Flux_gST(IJK)
            ENDIF
         ENDIF

         IF (FLUID_AT(IJK)) THEN 
            APO = ROP_GO(IJK)*C_PG(IJK)*VOL(IJK)*ODT 
            S_P(IJK) = APO + S_RPG(IJK)*VOL(IJK) 
            S_C(IJK) = APO*T_GO(IJK)-HOR_G(IJK)*VOL(IJK)+S_RCG(IJK)*VOL(IJK)
            IF(USE_MMS) S_C(IJK) = S_C(IJK) + MMS_T_G_SRC(IJK)*VOL(IJK)
         ELSE 
            S_P(IJK) = ZERO 
            S_C(IJK) = ZERO 
         ENDIF 
      ENDDO 

! Account for heat transfer between the discrete particles and the gas phase.
      IF(DES_CONTINUUM_COUPLED) CALL DES_Hgm(S_C, S_P)

! calculate the convection-diffusion terms
      CALL CONV_DIF_PHI (T_g, K_G, DISCRETIZE(6), U_G, V_G, W_G, &
         CpxFlux_E, CpxFlux_N, CpxFlux_T, 0, A_M, B_M, IER) 

! calculate standard bc
      CALL BC_PHI (T_g, BC_T_G, BC_TW_G, BC_HW_T_G, BC_C_T_G, 0, A_M, B_M, IER) 

! set the source terms in a and b matrix equation form
      CALL SOURCE_PHI (S_P, S_C, EP_G, T_G, 0, A_M, B_M, IER) 

! add point sources
      IF(POINT_SOURCE) CALL POINT_SOURCE_PHI (T_g, PS_T_g, &
         PS_CpxMFLOW_g, 0, A_M, B_M, IER)

      DO M = 1, TMP_SMAX 
         DO IJK = IJKSTART3, IJKEND3
            I = I_OF(IJK)
            J = J_OF(IJK)
            K = K_OF(IJK) 

            IF (IS_ON_myPE_plus2layers(IP1(I),J,K)) THEN
               IF(.NOT.ADDED_MASS .OR. M /= M_AM) THEN
                  CpxFlux_E(IJK) = HALF * (C_ps(IJK,M) + C_ps(IP_OF(IJK),M)) * Flux_sE(IJK,M)
               ELSE   ! M=M_AM is the only phase for which virtual mass is added
                  CpxFlux_E(IJK) = HALF * (C_ps(IJK,M) + C_ps(IP_OF(IJK),M)) * Flux_sSE(IJK)
               ENDIF
            ENDIF
         
            IF (IS_ON_myPE_plus2layers(I,JP1(J),K)) THEN
               IF(.NOT.ADDED_MASS .OR. M /= M_AM) THEN
                  CpxFlux_N(IJK) = HALF * (C_ps(IJK,M) + C_ps(JP_OF(IJK),M)) * Flux_sN(IJK,M)
               ELSE
                  CpxFlux_N(IJK) = HALF * (C_ps(IJK,M) + C_ps(JP_OF(IJK),M)) * Flux_sSN(IJK)
               ENDIF
            ENDIF

            IF (IS_ON_myPE_plus2layers(I,J,KP1(K))) THEN
               IF(.NOT.ADDED_MASS .OR. M /= M_AM) THEN
                  CpxFlux_T(IJK) = HALF * (C_ps(IJK,M) + C_ps(KP_OF(IJK),M)) * Flux_sT(IJK,M)
               ELSE
                  CpxFlux_T(IJK) = HALF * (C_ps(IJK,M) + C_ps(KP_OF(IJK),M)) * Flux_sST(IJK)
               ENDIF
            ENDIF

            IF (FLUID_AT(IJK)) THEN 
               APO = ROP_SO(IJK,M)*C_PS(IJK,M)*VOL(IJK)*ODT 
               S_P(IJK) = APO + S_RPS(IJK,M)*VOL(IJK) 
               IF (ANY_IC_SG) THEN
                  IF (IC_SG_AT(IJK) /= UNDEFINED_I) THEN
                     V_t = GRAVITY*D_p0(1)*D_p0(1)*(RO_S(IJK,1)-RO_g(IJK))/(18.0d0*MU_G(IJK))      
                     L_STAR = V_T*V_T/GRAVITY

                     U_S_STAR = ABS(U_S(IJK,1))/V_T
                     V_S_STAR = ABS(V_S(IJK,1))/V_T
                     D_CYL_STAR = IC_D_CYL(IC_SG_AT(IJK))/L_STAR
                     A_CYL_STAR = IC_A_CYL(IC_SG_AT(IJK))/(2.0*IC_D_CYL(IC_SG_AT(IJK)))  ! A_CYL is defined differently for energy model
                     T_SUSP = (EP_G(IJK)*K_G(IJK)*C_PG(IJK)*T_G(IJK) &
                        + (1.0 - EP_G(IJK))*K_S(IJK,1)*C_PS(IJK,1)*T_S(IJK,1)) &
                        /(EP_G(IJK)*K_G(IJK)*C_PG(IJK) + &
                        (1.0 - EP_G(IJK))*K_S(IJK,1)*C_PS(IJK,1))
                     E_STAR = K_S(IJK,1)*IC_T_CYL(IC_SG_AT(IJK))/L_STAR**2
                     H_GSC_STAR = 3.09 &
                        + 0.0224*(EP_s(IJK,M)/0.1)**2 &
                        - 0.00207*(EP_s(IJK,M)/0.1)**3 &
                        - 1.13*(U_S_STAR + 1.0) &
                        + 0.567*(U_S_STAR + 1.0)**2 &
                        - 5.12*(D_CYL_STAR/100.0)**2 &
                        + 5.31*(D_CYL_STAR/100.0)**3 &
                        - 0.336*A_CYL_STAR**2 &
                        + 0.170*(A_CYL_STAR**2*LOG(A_CYL_STAR)) &
                        + 0.0616*((V_S_STAR + 7.6)/10.0)**3 &
                        - 0.152*((V_S_STAR + 7.6)/10.0)**3*LOG((V_S_STAR + 7.6)/10.0)
                     DT_STAR = (IC_T_CYL(IC_SG_AT(IJK)) - T_SUSP)/IC_T_CYL(IC_SG_AT(IJK))
                     Q_GSC = H_GSC_STAR*DT_STAR*E_STAR
                     H_limiter = DMIN1(EP_S(IJK,M)/EPS_lim,ONE)
                     Q_GSC = Q_GSC * H_limiter
                  ELSE   
                     Q_GSC = ZERO
                  ENDIF
               ELSE
                  Q_GSC = ZERO
               ENDIF
               S_C(IJK) = APO*T_SO(IJK,M) - HOR_S(IJK,M)*VOL(IJK) + &
                  S_RCS(IJK,M)*VOL(IJK) + Q_GSC*VOL(IJK)
               VXGAMA(IJK,M) = GAMA_GS(IJK,M)*VOL(IJK) 
               EPS(IJK) = EP_S(IJK,M) 
               IF(USE_MMS) S_C(IJK) = S_C(IJK) + MMS_T_S_SRC(IJK)*VOL(IJK)
            ELSE 
               S_P(IJK) = ZERO 
               S_C(IJK) = ZERO 
               VXGAMA(IJK,M) = ZERO 
               EPS(IJK) = ZERO 
               IF(USE_MMS) EPS(IJK) = EP_S(IJK,M)
            ENDIF 
         ENDDO   ! end do (ijk=ijkstart3,ijkend3)

! calculate the convection-diffusion terms
         CALL CONV_DIF_PHI (T_s(1,M), K_S(1,M), DISCRETIZE(6), &
            U_S(1,M), V_S(1,M), W_S(1,M), CpxFlux_E, CpxFlux_N, &
            CpxFlux_T, M, A_M, B_M, IER) 

! calculate standard bc
         CALL BC_PHI (T_s(1,M), BC_T_S(1,M), BC_TW_S(1,M), &
            BC_HW_T_S(1,M), BC_C_T_S(1,M), M, A_M, B_M, IER) 

! set the source terms in a and b matrix equation form
         CALL SOURCE_PHI (S_P, S_C, EPS, T_S(1,M), M, A_M, B_M, IER) 

! Add point sources.
         IF(POINT_SOURCE) CALL POINT_SOURCE_PHI (T_s(:,M), PS_T_s(:,M),&
            PS_CpxMFLOW_s(:,M), M, A_M, B_M, IER)

      ENDDO   ! end do (m=1,tmp_smax)

! use partial elimination on interphase heat transfer term
      IF (TMP_SMAX > 0 .AND. .NOT.USE_MMS) &
        CALL PARTIAL_ELIM_S (T_G, T_S, VXGAMA, A_M, B_M, IER) 

      CALL CALC_RESID_S (T_G, A_M, B_M, 0, NUM_RESID(RESID_T,0),& 
         DEN_RESID(RESID_T,0), RESID(RESID_T,0), MAX_RESID(RESID_T,&
         0), IJK_RESID(RESID_T,0), ZERO, IER) 

      CALL UNDER_RELAX_S (T_G, A_M, B_M, 0, UR_FAC(6), IER) 

!      call check_ab_m(a_m, b_m, 0, .false., ier)
!      call write_ab_m(a_m, b_m, ijkmax2, 0, ier)
!      write(*,*) &
!         resid(resid_t, 0), max_resid(resid_t, 0), &
!         ijk_resid(resid_t, 0)


      DO M = 1, TMP_SMAX 
         CALL CALC_RESID_S (T_S(1,M), A_M, B_M, M, NUM_RESID(RESID_T,M), &
            DEN_RESID(RESID_T,M), RESID(RESID_T,M), MAX_RESID(&
            RESID_T,M), IJK_RESID(RESID_T,M), ZERO, IER) 

         CALL UNDER_RELAX_S (T_S(1,M), A_M, B_M, M, UR_FAC(6), IER) 
      ENDDO 

! set/adjust linear equation solver method and iterations 
      CALL ADJUST_LEQ(RESID(RESID_T,0), LEQ_IT(6), LEQ_METHOD(6), &
         LEQI, LEQM, IER) 
!      call test_lin_eq(a_m(1, -3, 0), LEQI, LEQM, LEQ_SWEEP(6), LEQ_TOL(6), LEQ_PC(6),  0, ier)

      CALL SOLVE_LIN_EQ ('T_g', 6, T_G, A_M, B_M, 0, LEQI, LEQM, &
         LEQ_SWEEP(6), LEQ_TOL(6), LEQ_PC(6), IER)  
! Check for linear solver divergence.
      IF(ier == -2) Err_l(myPE) = 120

! bound temperature in any fluid or flow boundary cells
      DO IJK = IJKSTART3, IJKEND3
         IF(.NOT.WALL_AT(IJK))&
            T_g(IJK) = MIN(TMAX, MAX(TMIN, T_g(IJK)))
      ENDDO

!      call out_array(T_g, 'T_g')

      DO M = 1, TMP_SMAX 
         CALL ADJUST_LEQ (RESID(RESID_T,M), LEQ_IT(6), LEQ_METHOD(6), &
            LEQI, LEQM, IER) 
!         call test_lin_eq(a_m(1, -3, M), LEQI, LEQM, LEQ_SWEEP(6), LEQ_TOL(6), LEQ_PC(6),  0, ier)
         CALL SOLVE_LIN_EQ ('T_s', 6, T_S(1,M), A_M, B_M, M, LEQI, &
            LEQM, LEQ_SWEEP(6), LEQ_TOL(6), LEQ_PC(6), IER) 

! Check for linear solver divergence.
         IF(ier == -2) Err_l(myPE) = 121

! bound temperature in any fluid or flow boundary cells
         DO IJK = IJKSTART3, IJKEND3
            IF(.NOT.WALL_AT(IJK))&
               T_s(IJK, M) = MIN(TMAX, MAX(TMIN, T_s(IJK, M))) 
         ENDDO
      ENDDO   ! end do (m=1, tmp_smax)
      
      call unlock_ambm
      call unlock_tmp_array
      call unlock_tmp_array1

! If the linear solver diverged, temperatures may take on unphysical
! values. To prevent them from propogating through the domain or
! causing failure in other routines, force an exit from iterate and
! reduce the time step.
      CALL global_all_sum(Err_l, Err_g)
      IER = maxval(Err_g)

      
      RETURN  
      END SUBROUTINE SOLVE_ENERGY_EQ