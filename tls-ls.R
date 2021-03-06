TLS_Gen <- function (In, y, mode = 1, scaling = 0, ef = 0)
{
  # m - variables qty
  # n - equations qty
  # mode - type of solution, 1 - SVD, 2 - eigen values
  # scaling - sort of scaling in case of TLS solution, bit mask: 1 - by rows, 2 - by columns, 3 - Frobenian
  # ef - error-free variables qty
  # In - equations, In(n,m)
  # y - observations, y(n)
  
  # X - solution, X(m)
  # E - discripency, E(n)
  # S - Singular Values or eigen values, depends on mode, S(m+1)
  # Corr - covariance matrix or corrilation matrix, Corr(m,m)
  # s0 - mean square deviation of the model
  # s0_dis - mean square deviation of the solution by discripency 
  # s_X - solution errors, s_X(m)
  # err - error code or condition number
  
  
  #---------------------------------------------------------------
  #     (TLS, ���) � ����� ����
  
  #doubleprecision, allocatable :: a(:,:), b(:,:),U(:,:), V(:,:), dn(:,:), cn(:,:), 
  #doubleprecision ee(m,m),c(m,m),d(m,m),d1(m,m)
  
  m <- dim(In)[2]
  n <- dim(In)[1]
  
  Result <- list(X = vector("numeric", m), s0 = numeric(), s0_dis = numeric(), s_X = vector("numeric", m), err = numeric(), CondA = numeric(),
                 Corr = matrix(0, m, m), Cov = matrix(0, m, m), E = vector("numeric", n), S = vector("numeric", m+1))

  
  Result$s0<-0; Result$s0_dis<-0;
  
  if ((m>=n) | (n<3) | (m<2))
  { 
    print("Error! m >= n")
    Result$err<- (-65535)
    return(Result);
  }
  
  
  # ===================================================================
  # ========= ���������� ����������� ����� ������� �������� ������ ��� ������ ����� ���������������  
  # ========= The Total Least Square Problem, p. 232
  # ===================================================================
  in_svd <- svd(In)  
  Result$CondA <- in_svd$d[1]/in_svd$d[m]

  # =========== ���������� �������� ������, ��������� ����������� ������� �������� ���������
  
  a <- cbind(In, y);
  
  # ===================================================================
  # ========= ������������ �������� ������
  # ========= The Total Least Square Problem, p. 90, $3.6.2, (3.125)
  # ===================================================================
  if (scaling>0)
  {
  
      dn <- matrix(0, n, n);
      cn <- matrix(0, m+1, m+1);
      
      # �� ��������   
      
      if ((scaling==1) || (scaling==3))
      {
        
        for (i in 1:n)
          dn[i,i] <- 1 / sqrt(sum(a[i,]^2));
                              
        a <- dn %*% a;
      }
      
      # �� ��������
      # ��� ������ TLS-LS �������� ����� ����������� �� ��� �������, � ������ ��, 
      # ��� �������� ������ (!!!ToDo)
      
      if ((scaling==2) || (scaling==3)) 
      {
        
        # ������ ����� �������� �� ��� ��� ����� (�������������, ���� �������� � �����), 
        # �������� ������ ������ ���������� ������ ���� �����. ��������� �� �� �����, �� 
        # ����� ������������, ��� ��������� ������ ���������� ��������������� �������� ����� ���������, 
        # � ������ ���� ������ ����������� ������� �������� ��������� ���, ����� �������� 
        # ������������� ��� ������ ���������� ����� �������� ���������� �����. 
        # ������������ ���� ������� ��������. 
        
        c <- vector("numeric", m+1);
        for(i in 1:(m+1)){
           c[i] <- sqrt(sum(a[,i]^2))
        }
        c_0 <- mean(c)   
                         
        c <- c_0/c
        
        cn <- diag(c);
         
        a <- a %*% cn
      }
      
      # ����� ����������
      #if (scaling==4){ 
      #  call NR2RR (a, fn)   #  !!!
      #}
      
  }
  
  # ===================================================================
  # ====================   ���������� �������
  # ============ ������� ����� ����������� ����������
  # ===================================================================
  if (mode == 1){
     a_svd <- svd(a); 
    
     #----  �������� �������
     Result$S <- a_svd$d  # ������ ����������� �����
     #aa <- a_svd$u %*% (diag(a_svd$d) %*% t(a_svd$v) );  # ��������
     #ee <- aa-a; 
     
     #----  ��������� �
     x2 <-  a_svd$v[,m+1];  
     
     if ((scaling==2) || (scaling==3)) 
        x2 <- cn %*% x2; 
     
     x2 <- -1*x2/x2[m+1]
     Result$X <- x2[1:m];
     
     #---- ���������� ����� ���������������
     #---- ��� ��� ���� ���������, Branham, Astronomical Data Reduction with TLS, p.655
     Result$err<- (in_svd$d[1]^2-a_svd$d[m+1]^2)/(in_svd$d[m]^2-a_svd$d[m+1]^2);
     
     #----  ���������� �������������������� ����������, The Total Least Squares Problem, 8.15
     Result$s0 <- a_svd$d[m+1] / sqrt(n+0.0);
     
     #---- ���������� �������������� �������, The Total Least Squares Problem, page 242, 8.47
     d <- matrix(0, m, m) ;
     diag(d) <- a_svd$d[m+1]^2;
     d1 <- (t(In) %*% In) - d;
     Result$Cov <- solve(d1)
     Result$Cov <- (1+sum(Result$X^2)) * a_svd$d[m+1]^2 * Result$Cov / n;
     
  } else if (mode == 2) {
  # ===================================================================
  # ===========  ������� ����� ����������� �����
  # ===================================================================
      ss <- t(a) %*% a;  # ��������� ������� ���������
  
      if ((ef==0) || (ef>m))# ������� �������� TLS, ��� ���������� �������� ������
      {
          #print("������� �������� TLS, ��� ���������� �������� ������")
          nef <- m+1;
      
          s_c <- eigen(ss);
          Result$S <- s_c$val;
          
          if (Result$S[m+1]<0) Result$S[m+1] <- 0;
          ee <- diag(rep(Result$S[m+1], m))

          #----  ���������� sigma_0, The Total Least Squares Problem, 8.15
          Result$s0 <- sqrt(Result$S[m+1])/sqrt(n+0.0);
          #---- ���������� ����� ���������������
          Result$err<- (in_svd$d[1]^2-Result$S[m+1])/(in_svd$d[m]^2-Result$S[m+1]);
          
          #---- �������� ���������� �������������� �������, �� �������� � The Total Least Squares Problem, page 242, 8.47
          
          d <- matrix(0, m , m);
          d <- diag(rep(Result$S[m+1], m));
          d1 <- t(In) %*% In - d;
          Result$Cov <- solve(d1);
          
          
  #    ���� ������� ������ (����� ������ ������ ������� error-free) ����� � ����� �����, ������������� ����. ��� �������, �� ������ ������ ��������
  #    elseif (ef==-1) then     
  #     nef=m;
  #     allocate (b21v(m),b12v(m),b22(m, m), b_shur(m, m), s_b(m));
  #     b21v = ss(1,2:m+1);
  #     b12v = ss(2:m+1, 1);
  #     b22 = ss(2:m+1,2:m+1);
  #     do i=1,m
  #       do j=1,m
  #         b_shur(i,j) = b21v(i)*b12v(j)
  #       enddo
  #     enddo
  
  #     b_shur = b_shur/ss(1,1);
  #     b_shur = b22 - b_shur
  
  #!     call lin_eig_gen(b_shur, s_b);     
  #!     ee = 0;
  #!     s=0;
  #!     do i=2,m
  #!       ee(i,i) = s_b(m);      
  #!       s(i-1) = s_b(i-1)
  #!     enddo   
  #!     s(m) = s_b(m);
  #!     deallocate(b21v, b12v, b22, b_shur, s_b);
  
      } else if (ef==m) # �������, ����� ��� ������� error-free
      {
        ee <- matrix(0, m, m);
        
        d1 <- t(In) %*% In;
        Result$Cov <- solve(d1);
        
        Result$err<- (in_svd$d[1]^2)/(in_svd$d[m]^2);
        
      } else {   #! ������� TLS-LS, ����� ������ ef-�������� �� �������� ������, � ��������� nef - ��������
          nef <- m+1-ef; 
          #print("������� TLS-LS")
          #b21(nef,ef), b12(ef,nef),b22(nef, nef), b_shur(nef, nef),b_inv(ef,ef), s_b(nef), b11(ef,ef)
          
          b12 <- as.matrix(ss[1:ef,(ef+1):(m+1)]);
          if (ef == 1) b12 <- t(b12)
          b21 <- as.matrix(ss[(ef+1):(m+1), 1:ef]);
          if (ef == m) b21 <- t(b21)
          b22 <- as.matrix(ss[(ef+1):(m+1),(ef+1):(m+1)]);
          b11 <- as.matrix(ss[1:ef,1:ef]);
          
          b_inv <- solve(b11)

          b_shur <- b22 - (b21 %*% b_inv) %*% b12;
          
          s_b <- eigen(b_shur)

          ee <- diag(c(rep(0, ef), rep(s_b$val[nef], m-ef)))
          
          Result$S[1:nef] <- s_b$val
          
          #----  ���������� sigma_0, �� �������� � The Total Least Squares Problem, 8.15, �������� �� ���������, ���� ���-�� ���������
          Result$s0 <- sqrt(Result$S[nef])/sqrt(n+0.0);
          
          #---- �������� ���������� �������������� �������, �� �������� � The Total Least Squares Problem, page 242, 8.47, �������� �� ���������, ���� ���-�� ���������
          
          d <- matrix(0, m , m);
          d <- diag(rep(s_b$val[nef], m));
          
          d1 <- t(In) %*% In - d;
          Result$Cov <- solve(d1);
          
          #---- ���������� ����� ���������������
          Result$err<- (in_svd$d[1]^2-Result$S[nef])/(in_svd$d[m]^2-Result$S[nef]);
  
      }
  
    #--------- ���������� ������� ���������� ���������
    c<-t(a[,1:m]) %*% a[,1:m]-ee;  # ������ � ����������������
    
    #---------  ���������� �������� �������
    d <- solve(c) 
    #ee <- c %*% d;  # ��������
    
    #----   ���������� �������  
    Result$X <- as.vector(d %*% (t(a[,1:m]) %*% a[,m+1])); # � ������ ���������������
    
    if ((scaling==2) || (scaling==3))
      Result$X <- as.vector((cn[1:m, 1:m] %*% Result$X) / cn[m+1,m+1]); 
    
    #---- ����������� ���������� �������������� ������� �� �������� � TLS, ���� ���������� �� ������� �� �������
    if (ef<m)
      Result$Cov <- (1+sum(Result$X^2)) * Result$s0^2 * Result$Cov;
    
  }

  #-------   ���������� �������
  Result$E <- y - In %*% Result$X;
  
  #---- ���������� ��������������������� ���������� �� �������� 
  Result$s0_dis <- sqrt(sum(Result$E*Result$E)/(n-m))
  
  if ((mode == 2 ) && (ef == m))
    Result$s0 <- Result$s0_dis;
  
  #---- ���������� ������ ������������� �������
  Result$s_X <- Result$s0 * sqrt(diag(Result$Cov))
  
  
  #---- ���������� �������������� �������
  Result$Corr <- matrix(0, m, m)
  for (i in 1:m)
    for (j in 1:m)
      Result$Corr[i,j]=Result$Cov[i,j]/sqrt(Result$Cov[i,i]*Result$Cov[j,j])
  
  #print(X);
  #print(s0);
  #print(s0_dis);
  #print(s_X);
  #print(err)
  #print(Cov);
  return(Result)

}

TLS_Gen_test <- function()
{
  scaling <- 2;
  
  m<-9; 
  n<- 1000;
  ef <- 4;
  X_0 <- c(-2, -1, 2, 1, 2, -1, 2, -6, +5, -3);
  print(X_0);
  
  S_0 <- c(rep(0.0, ef), rep(0.5, m-ef), 0.1);
  print(S_0)
  
  In <- TLS_make_test_data(n, m, X_0, S_0); 
  
  TLS_Gen_Solve(In, n, m, ef, scaling)
}

TLS_Gen_Solve <- function(In, n, m, ef, scaling)
{
  
  print(In$X_0);
  print(In$S_0)
  print(norm(t(In$A)%*%In$A, type="i")*norm(solve(t(In$A)%*%In$A), type = "i"))
  print(scaling)
  print("---------")
  
  print("SVD solution:")
  res <- TLS_Gen(In$A, In$B, mode = 1, scaling)
  print(res$X)
  print(In$X_0[1:m] - res$X)
  print(res$s_X)
  print(res$s0)
  print(res$s0_dis)
  print(sqrt(sum((In$B0 - In$A0 %*% res$X)^2)/(n-m)))
  #print(res$Cov)
  print(res$Corr)
  print(res$err)
  print("---------")
  
  print("Eigen value solution, TLS case, all variables consist erros:")
  res <- TLS_Gen(In$A, In$B, mode = 2, scaling, ef = 0)
  print(res$X)
  print(In$X_0[1:m] - res$X)
  print(res$s_X)
  print(res$s0)
  print(res$s0_dis)
  print(sqrt(sum((In$B0 - In$A0 %*% res$X)^2)/(n-m)))
  #print(res$Cov)
  print(res$Corr)
  print(res$err)
  print("---------")
  
  print("Eigen value solution, TLS-LS case, known variables error-free")
  res <- TLS_Gen(In$A, In$B, mode = 2, scaling, ef)
  print(res$X)
  print(In$X_0[1:m] - res$X)
  print(res$s_X)
  print(res$s0)
  print(res$s0_dis)
  print(sqrt(sum((In$B0 - In$A0 %*% res$X)^2)/(n-m)))
  #print(res$Cov)
  print(res$Corr)
  print(res$err)
  print("---------")
  
  print("OLS solution, all variables error-free:")
  res <- TLS_Gen(In$A, In$B, mode = 2, scaling, m)
  print(res$X)
  print(In$X_0[1:m] - res$X)
  print(res$s_X)
  print(res$s0)
  print(res$s0_dis)
  print(sqrt(sum((In$B0 - In$A0 %*% res$X)^2)/(n-m)))
  #print(res$Cov)
  print(res$Corr)
  print(res$err)
  print("---------")
  
  print("TLS solution by R prcomp function:")
  r <- prcomp( ~ In$A + In$B )
  x <- r$rotation[1:m,m+1]/(-1*r$rotation[m+1,m+1]);
  print(x)
  print(In$X_0[1:m] - x)
  print(sqrt(sum((In$B - In$A %*% x)^2)/(n-m)))
  print(sqrt(sum((In$B0 - In$A0 %*% x)^2)/(n-m)))
  print("---------")
  
  print("OLS solution by R lm function:")
  #f <- lm(In$B ~ 0 + In$A[,1] + In$A[,2] + In$A[,3] + In$A[,4] + In$A[,5] + In$A[,6] + In$A[,7] + In$A[,8] + In$A[,9])
  f <- lm(In$B ~ 0 + In$A[,1] + In$A[,2] + In$A[,3] + In$A[,4] + In$A[,5] + In$A[,6] + In$A[,7] + In$A[,8] + In$A[,9]  + In$A[,10]  + In$A[,11]  + In$A[,12])
  print(f$coefficients)
  print(In$X_0[1:m] - f$coefficients)
  print(sqrt(sum(f$residuals*f$residuals)/(n-m)))
  print(sqrt(sum((In$B0 - In$A0 %*% f$coefficients)^2)/(n-m)))
  print("---------")
  
}