library(dplyr)

rank_dist <- function(row) {
  hospemp<-row$selectedhospitalemp
  hospsim<-row$selectedhospital
  hospempname<-row$name_selectedhospitalemp
  hospsimname<-row$name_selectedhospital
  compaz<-row$pro_com
  comemp<-hospital_list[which(hospital_list$who_hospital==hospemp), c("pro_com_hospital")]
  comsim<-hospital_list[which(hospital_list$who_hospital==hospsim), c("pro_com_hospital")]
  dist_emp<-distance[which(distance$X==compaz), which(colnames(distance)==paste("X",comemp, sep = ""))]
  dist_sim<-distance[which(distance$X==compaz), which(colnames(distance)==paste("X",comsim, sep = ""))]
  dist_min<-min(distance[which(distance$X==compaz), ])
  rank_emp<-ranking_pne[which(ranking_pne$presidio==hospempname), c("rankinit")]
  
  rl<-row$rankinglist
  list<-gsub("\\[", "", gsub("\\]", "", unlist(regmatches(rl, gregexpr("\\[([^]]+)\\]", rl)))))
  mat <- data.frame(t(sapply(strsplit(list, " "), as.numeric)))
  colnames(mat)<-c("id", "rank")
  rank_sim_pat<-mat[which(mat$id==hospsim), c("rank")]
  
  rank_sim_pne<-ranking_pne[which(ranking_pne$presidio==hospsimname), c("rankinit")]
  
  c(rank_pat = rank_sim_pat, rank_pne = rank_sim_pne, dist = dist_sim, dist_min = dist_min)

}

hospital_list <- read.csv("C:/Users/Pecoraro/Desktop/childbirthnet-soc_exp_od/data/mapping_hospitals.csv", sep = ";")
ranking_pne <- read.csv("C:/Users/Pecoraro/Desktop/childbirthnet-soc_exp_od/data/ranking_hospitals.csv")
distance <- read.csv("C:/Users/Pecoraro/Desktop/childbirthnet-soc_exp_od/data/matrice_distanze_ospedali.csv")
# distance <- read.csv("C:/Users/Pecoraro/Desktop/childbirthnet-soc_exp_od/data/normalized_distance.csv")

file_list <- list.files(path = "C:/Users/Pecoraro/Desktop/childbirthnet-soc_exp_od/data_bs", pattern = "\\.csv$", full.names = TRUE)

n <- length(file_list)

# file<-file_list[1]

result_patient<-NULL

pb <- txtProgressBar(min = 0, max = n, style = 3)

i_start<-1 # 18000
i_stop<-Inf #20177

# patient analysis 
for (file in file_list) {
  df<-read.csv(file)
  
  df<-df[which(df$timeatbirth>=i_start & df$timeatbirth<=i_stop), ]
  
  result_file<-cbind(df[, c("who", "pro_com", "selectedhospital", "weight_distance_hospital", "social_multiplier", "weight_experience", "distance_threshold")])
  result_file$dist_sim<-NA
  result_file$dist_min<-NA
  result_file$rank_sim_pat<-NA
  result_file$rank_sim_pne<-NA
  for (i in 1:nrow(df)) {
    result<-rank_dist(df[i, ])
    result_file[i, c("rank_sim_pat")]<-as.numeric(result[1])
    result_file[i, c("rank_sim_pne")]<-as.numeric(result[2])
    result_file[i, c("dist_sim")]<-as.numeric(result[3])
    result_file[i, c("dist_min")]<-as.numeric(result[4])
  }
  result_patient<-rbind(result_patient, result_file)  
  Sys.sleep(0.05)  # solo per simulare tempo
  setTxtProgressBar(pb, which(file_list == file))
}

result_patient<-result_patient[, c("who", "distance_threshold", "weight_distance_hospital", "social_multiplier", "weight_experience", "dist_sim", "dist_min", "rank_sim_pat", "rank_sim_pne")]

result_patient$dist_min_rank <- ifelse(result_patient$dist_min<=0, 0, 
                                       ifelse(result_patient$dist_min<=15, 1, 
                                              ifelse(result_patient$dist_min<=30, 2, 
                                                     ifelse(result_patient$dist_min<=45, 3, 4))))

# table(result_patient$dist_min)

result_summary <- result_patient %>%
  group_by(distance_threshold, weight_experience, social_multiplier) %>%
  summarise(
    mean_dist = mean(dist_sim, na.rm = TRUE),
    sd_dist   = sd(dist_sim, na.rm = TRUE),
    mean_rank_pat = mean(rank_sim_pat, na.rm = TRUE),
    sd_rank_pat = sd(rank_sim_pat, na.rm = TRUE), 
    mean_rank_pne = mean(rank_sim_pne, na.rm = TRUE),
    sd_rank_pne   = sd(rank_sim_pne, na.rm = TRUE)
)




