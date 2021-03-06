

draw_tgas_hist_Z <- function(tgas_, name_){
  tgas_ <- CalcGalXYZ(tgas_)
  g<- ggplot(data = tgas_) + geom_histogram(aes(x = z), fill = "gray70", colour = "gray10") + 
    scale_x_continuous(breaks=seq(-0.5,0.5,by=0.1), minor_breaks=seq(-0.5,0.5,by=0.05), limits = c(-0.5,0.5)) #+ 
    #scale_y_continuous(breaks=seq(0,250000,by=25000), minor_breaks=seq(0,250000,by=12500)) + 
    theme_bw()
  
  ggsave(filename = paste0(name_, ".jpeg"), width = 5, height = 5)
         
  return(g);
}


tgas_make_z_hist <- function(tgas)
{
  tgas_ <- tgas %>% filter(!is.na(B_V) & !is.na(M) & (LClass_apass == 5))
  draw_tgas_hist_Z(tgas_, name_ = "TGAS_MS_Z_all_stars")
  
  tgas_ <- tgas %>% filter(!is.na(B_V) & !is.na(M) & (LClass_apass == 5) & ((B_V>1.42) & (B_V<Inf)))
  draw_tgas_hist_Z(tgas_, name_ = "TGAS_MS_Z_M-stars")
                  
  tgas_ <- tgas %>% filter(!is.na(B_V) & !is.na(M) & (LClass_apass == 5) & ((B_V>0.85) & (B_V<1.42)))
  draw_tgas_hist_Z(tgas_, name_ = "TGAS_MS_Z_K-stars")
  
  tgas_ <- tgas %>% filter(!is.na(B_V) & !is.na(M) & (LClass_apass == 5) & ((B_V>0.58) & (B_V<0.85)))
  draw_tgas_hist_Z(tgas_, name_ = "TGAS_MS_Z_G-stars")
  
  tgas_ <- tgas %>% filter(!is.na(B_V) & !is.na(M) & (LClass_apass == 5) & ((B_V>0.29) & (B_V<0.58)))
  draw_tgas_hist_Z(tgas_, name_ = "TGAS_MS_Z_F-stars")
  
  tgas_ <- tgas %>% filter(!is.na(B_V) & !is.na(M) & (LClass_apass == 5) & ((B_V>0.0) & (B_V<0.29)))
  draw_tgas_hist_Z(tgas_, name_ = "TGAS_MS_Z_A-stars")
  
  tgas_ <- tgas %>% filter(!is.na(B_V) & !is.na(M) & (LClass_apass == 5) & ((B_V>(-0.3)) & (B_V<0.0)))
  draw_tgas_hist_Z(tgas_, name_ = "TGAS_MS_Z_B-stars")
  
  tgas_ <- tgas %>% filter(!is.na(B_V) & !is.na(M) & (LClass_apass == 5)) %>% filter(B_V>(-Inf)) %>% filter(B_V<(-0.3))
  draw_tgas_hist_Z(tgas_, name_ = "TGAS_MS_Z_O-stars")
  
}

tgas_make_all_diagrams_by_sample <- function(tgas_, name)
{
  draw_tgas_hist_Z(tgas_, name_ = paste0(name, "_Z_M-stars"))
  ggplot(data = tgas_) + geom_histogram(aes(x = Mag), fill = "gray70", colour = "gray10") +
    scale_x_continuous(breaks=seq(7,15,by=1), minor_breaks=seq(7,15,by=0.25), limits = c(7,15)) +
    theme_bw()
  ggsave(filename = paste0(name, "_M_APASS_V.jpeg"), width = 5, height = 5)
  HRDiagram(tgas_, save = name, photometric = "none")
  DrawGalaxyPlane(tgas_, plane = "XY", save = name, dscale = 0.5)
  DrawGalaxyPlane(tgas_, plane = "XZ", save = name, dscale = 0.5)
  DrawGalaxyPlane(tgas_, plane = "YZ", save = name, dscale = 0.5)
}
