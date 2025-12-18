library(dplyr)
library(readxl)
library(readr)
library(tidyr)
library(tidyverse)
library(ggplot2)
library(ggrepel)


setwd("C:/Users/LENOVO/Documents/GitHub/childbirthod/")

# processing data ####
# path <- "dataset_experiments/"
# files <- list.files(path, pattern = ".csv$", full.names = TRUE)
# 
# combined_df <- files %>%
#   set_names() %>%                             # keep filenames as names
#   imap_dfr(~ read_csv(.x))  # add cond_n as progressive number
# 
# combined_df <- combined_df %>%
#   dplyr::group_by(
#     rescale15, initrankrnd, initrank_sd, distance_threshold, n_network,
#     weight_distance_hospital, weight_opinion, social_multiplier,
#     weight_experience, uptrnk_sd, eps_birthtrue, eps_notbirth,
#     mu_birthtrue, mu_notbirth
#   ) %>%
#   dplyr::mutate(condition = dplyr::cur_group_id()) %>%
#   dplyr::ungroup()
# 
# combined_df <- combined_df %>% select(condition, everything())
# 
# df_summary <- combined_df %>%
#   group_by(condition) %>%
#   summarise(n = n()) %>%
#   arrange(condition)
# 
# ######################
# 
# parse_netlogo_table <- function(s, suffix) {
#   if (is.na(s) || !nzchar(s)) return(setNames(numeric(0), character(0)))
#   # strip wrappers
#   s <- str_remove(s, "^\\{\\{table:\\s*")
#   s <- str_remove(s, "\\}\\}\\s*$")
#   
#   # capture [ key  value ] where key may be "48.0" or 48
#   pairs <- str_match_all(
#     s,
#     "\\[\\s*\"?(-?\\d+(?:\\.\\d+)?)\"?\\s+(-?\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?)\\s*\\]"
#   )[[1]]
#   if (nrow(pairs) == 0) return(setNames(numeric(0), character(0)))
#   
#   # keys as numeric to normalize (so "48.0" -> 48), then to character without trailing .0
#   keys_num <- as.numeric(pairs[, 2])
#   # If a key fails to parse (unlikely here), fall back to the raw string
#   keys_chr <- ifelse(
#     is.na(keys_num),
#     pairs[, 2],
#     sub("\\.0+$", "", format(keys_num, trim = TRUE, scientific = FALSE))
#   )
#   
#   vals <- as.numeric(pairs[, 3])
#   
#   # sort by numeric key so columns come out in ascending order
#   ord <- order(suppressWarnings(as.numeric(keys_chr)))
#   setNames(vals[ord], paste0(keys_chr[ord], "_", suffix))
# }
# 
# # Helper to expand ONE source column into many wide columns
# expand_table_column <- function(df, col, suffix) {
#   col <- rlang::ensym(col)
#   df %>%
#     mutate(.expanded = map(!!col, ~ parse_netlogo_table(.x, suffix))) %>%
#     unnest_wider(.expanded, names_repair = "check_unique")
# }
# 
# # ---- Apply to your data ----
# # Assuming your data is in `combined_df`
# # pricechoicelist -> *_prechoice
# # rankinglist     -> *_rankinglist
# combined_dfwide <- combined_df %>%
#   expand_table_column(prechoicelist, "prechoicelist") %>%
#   expand_table_column(rankinglist, "rankinglist")
# 
# # Put *_prechoice columns together, then *_rankinglist; keep all other cols first
# derived_pre  <- grep("_(prechoicelist|prechoicelist)$", names(combined_dfwide), value = TRUE)
# derived_rank <- grep("_rankinglist$",               names(combined_dfwide), value = TRUE)
# base_cols    <- setdiff(names(combined_dfwide), c(derived_pre, derived_rank))
# 
# combined_dfwide <- combined_dfwide %>%
#   select(all_of(base_cols), all_of(derived_pre), all_of(derived_rank))
# 
# combined_dfwide <- df2
# 
# 
# 
# load("combined_dfwide.Rdata")
# 
# ### barplot
# 
# combined_dfwide$rankinit <- NA
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "AREA ARETINA NORD AREZZO",]$rankinit <- 1
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSPEDALE DEL VALDARNO - \"S.MARIA DELLA GRUCCIA\"",]$rankinit <- -1
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "COMPLESSO OSPEDALIERO CAREGGI - CTO (FI)",]$rankinit <- 1
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "LE SCOTTE SIENA",]$rankinit <- 0.5
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSP. RIUNITI DELLA VAL DI CHIANA",]$rankinit <- -1
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "MISERICORDIA GROSSETO",]$rankinit <- 0
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "NUOVO OSPEDALE BORGO S.LORENZO (FI)",]$rankinit <- -1
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSPEDALE DELL'ALTA VAL D'ELSA POGGIBONSI",]$rankinit <- 0.5
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "SS. GIACOMO E CRISTOFORO MASSA",]$rankinit <- 0.5
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "S.M. ANNUNZIATA BAGNO A RIPOLI",]$rankinit <- 0
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSPEDALI PISANI (PI)",]$rankinit <- 1
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "RIUNITI LIVORNO",]$rankinit <- 0.5
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "S.GIOVANNI DI DIO-TORREGALLI (FI)",]$rankinit <- 1
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "NUOVO OSPEDALE DI PRATO S.STEFANO",]$rankinit <- 1
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "CIVILE CECINA (LI)",]$rankinit <- 0.5
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSPEDALE SAN JACOPO",]$rankinit <- 1
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSPEDALE S. GIUSEPPE",]$rankinit <- 0.5
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "F.LOTTI PONTEDERA (PI)",]$rankinit <- 0.5
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSPEDALE UNICO \"VERSILIA\"",]$rankinit <- 0
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "SAN ROSSORE",]$rankinit <- 0
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "CIVILE ELBANO PORTOFERRAIO (LI)",]$rankinit <- -1
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSPEDALE SAN LUCA",]$rankinit <- 0
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "SERRISTORI FIGLINE V.A. (FI)",]$rankinit <- -1
# combined_dfwide[combined_dfwide$name_selectedhospitalemp == "S. FRANCESCO BARGA (LU)",]$rankinit <- -1
# 
# combined_dfwide <- combined_dfwide %>%
#   rowwise() %>%
#   mutate(
#     distemp = {
#       x <- as.character(pro_com)
#       y <- as.character(procom_selectedhospitalemp)
#       val <- distcounsel[distcounsel$womencom == x, y]
#     }
#   ) %>%
#   ungroup()
# 
# combined_dfwide <- combined_dfwide %>%
#   rowwise() %>%
#   mutate(
#     distsim = {
#       x <- as.character(pro_com)
#       y <- as.character(procom_selectedhospital)
#       val <- distcounsel[distcounsel$womencom == x, y]
#     }
#   ) %>%
#   ungroup()
# 
# combined_dfwide <- combined_dfwide %>%
#   rowwise() %>%
#   mutate(
#     distempnorm = {
#       x <- as.character(pro_com)
#       y <- as.character(procom_selectedhospitalemp)
#       val <- df_normalized[df_normalized$womencom == x, y]
#     }
#   ) %>%
#   ungroup()
# 
# combined_dfwide <- combined_dfwide %>%
#   rowwise() %>%
#   mutate(
#     distsimnorm = {
#       x <- as.character(pro_com)
#       y <- as.character(procom_selectedhospital)
#       val <- df_normalized[df_normalized$womencom == x, y]
#     }
#   ) %>%
#   ungroup()
# 
# save(combined_dfwide,file="combined_dfwide.Rdata")

# analysis ####

load("experiments/combined_dfwide.Rdata")

conds <- combined_dfwide %>% select(condition,distance_threshold,	weight_distance_hospital,	weight_opinion, social_multiplier, weight_experience, uptrnk_sd)
conds <- unique(conds)


# condition 74
baselineemp <- combined_dfwide %>% filter(distance_threshold == 260 & weight_distance_hospital == -1 & weight_opinion == 0 & 
                                            social_multiplier == 0 & weight_experience == 0.5 & uptrnk_sd == 0.25) %>%
  group_by(selectedhospitalemp) %>%
  summarise(
    emp_cases = n(),
    emp_avgdist = mean(distemp, na.rm = TRUE),
    condition = unique(condition),
    rankinit = unique(rankinit),
    name = unique(name_selectedhospitalemp)
  ) %>%
  rename(hospital = selectedhospitalemp)


mergelong <- function(distance_threshold_v, weight_distance_hospital_v, weight_opinion_v, social_multiplier_v, weight_experience_v, uptrnk_sd_v) 
{ t <- combined_dfwide %>% filter(distance_threshold == distance_threshold_v & weight_distance_hospital == weight_distance_hospital_v & 
                                    weight_opinion == weight_opinion_v &  social_multiplier == social_multiplier_v & 
                                    weight_experience == weight_experience_v & uptrnk_sd == uptrnk_sd_v) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

p <- baselineemp %>%
  full_join(t, by = c("hospital","name"))%>%
  pivot_longer(
    cols = c(emp_cases, sim_cases, emp_avgdist, sim_avgdist),
    names_to = c("type", ".value"),
    names_pattern = "^(emp_|sim_)(.*)$"
  ) %>%
  mutate(
    type = recode(type,
                  "emp_" = "Empirical",
                  "sim_" = "Simulated"),
    condition = paste0("sim_","thr",distance_threshold_v,"ds", weight_distance_hospital_v,"op",weight_opinion_v,"soc", social_multiplier_v,"xp", weight_experience_v,"sd", uptrnk_sd_v)
  )
p
}

df1 <- mergelong( distance_threshold_v = 0, weight_distance_hospital_v = -1, weight_opinion_v = 0, 
                  social_multiplier_v = 0, weight_experience_v = 1, uptrnk_sd_v = 0.25)

df2 <- mergelong( distance_threshold_v = 0, weight_distance_hospital_v = -5, weight_opinion_v = 0, 
                  social_multiplier_v = 0, weight_experience_v = 1, uptrnk_sd_v = 0.25)

df3 <- mergelong( distance_threshold_v = 0, weight_distance_hospital_v = -1, weight_opinion_v =1, 
                  social_multiplier_v = 0, weight_experience_v = 1, uptrnk_sd_v = 0.25)

df4 <- mergelong( distance_threshold_v = 0, weight_distance_hospital_v = -5, weight_opinion_v = 5, 
                  social_multiplier_v = 0, weight_experience_v = 1, uptrnk_sd_v = 0.25)

df5 <- mergelong( distance_threshold_v = 0, weight_distance_hospital_v = -5, weight_opinion_v = 5, 
                  social_multiplier_v = 1, weight_experience_v = 1, uptrnk_sd_v = 0.25)

df6 <- mergelong( distance_threshold_v = 0, weight_distance_hospital_v = -5, weight_opinion_v = 5, 
                  social_multiplier_v = 1, weight_experience_v = 0.5, uptrnk_sd_v = 0.25)

df1_2 <- rbind(df1,df2[df2$type == "Simulated",])
df1_2$compscen <- "distance"
df1_2[df1_2$type == "Empirical",]$condition <- "Empirical"
df3_4 <- rbind(df3,df4[df4$type == "Simulated",])
df3_4$compscen <- "opinionxdistance"
df3_4[df3_4$type == "Empirical",]$condition <- "Empirical"
df5_6 <- rbind(df5,df6[df6$type == "Simulated",])
df5_6$compscen <- "socmult"
df5_6[df5_6$type == "Empirical",]$condition <- "Empirical"

sim_merge <- rbind(
  df1_2,
  df3_4,
  df5_6
)


pl_dist <- sim_merge %>% mutate(compscen = factor(compscen,
                                                  levels = c("distance", "opinionxdistance", "socmult"),
                                                  labels = c("A: Effect distance",
                                                             "B: Distance X OwnOpinion",
                                                             "C: Social Multiplier")))%>%
  filter(compscen == "A: Effect distance") %>%
  group_by(compscen,condition, type, rankinit) %>%
  summarise(
    avgdist = mean(avgdist, na.rm = TRUE),
    cases   = mean(cases,   na.rm = TRUE),
    n_hospitals = n_distinct(hospital),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = avgdist, y = cases,
             fill = condition,                  # map fill to type
             shape = factor(rankinit))) +  # shapes 21–25 support fill
  geom_point(size = 3, color = "black", stroke = 0.6) +
  scale_fill_manual(
    name = NULL,
    values = c("Empirical" = "lightblue", 
               "sim_thr0ds-1op0soc0xp1sd0.25" = "bisque",
               "sim_thr0ds-5op0soc0xp1sd0.25" = "lightgreen" ),
    labels = c(
      "Empirical",
      "sim_thr0ds-1op0soc0xp1sd0.25" = "ß distance = -1",
      "sim_thr0ds-5op0soc0xp1sd0.25" = "ß distance = -5"
    ),
    guide = guide_legend(                 # ensure legend keys show the fill
      override.aes = list(shape = 21,     # a fillable shape in the legend
                          color = "black",
                          size = 3)
    )
  ) +
  scale_shape_manual(
    name = "Rankinit",
    values = c("-1"=25, "0"=22, "0.5"=21, "1"=24)
  ) +
  facet_wrap(~compscen) +
  labs(x = "avg time distance", y = "hospitalizations") +
  theme_bw() +
  theme(legend.position = "bottom", 
        legend.title = element_text(size = 13),
        legend.text = element_text(size = 13),
        strip.text = element_text(size = 14) ,
        axis.title.x = element_text(size = 14),
        axis.title.y = element_text(size = 14)) + 
  guides(shape = "none")

pl_distxop <- sim_merge %>% mutate(compscen = factor(compscen,
                                                     levels = c("distance", "opinionxdistance", "socmult"),
                                                     labels = c("A: Effect distance",
                                                                "B: Distance X OwnOpinion",
                                                                "C: Social Multiplier")))%>%
  filter(compscen == "B: Distance X OwnOpinion") %>%
  group_by(compscen,condition, type, rankinit) %>%
  summarise(
    avgdist = mean(avgdist, na.rm = TRUE),
    cases   = mean(cases,   na.rm = TRUE),
    n_hospitals = n_distinct(hospital),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = avgdist, y = cases,
             fill = condition,                  # map fill to type
             shape = factor(rankinit))) +  # shapes 21–25 support fill
  geom_point(size = 3, color = "black", stroke = 0.6) +
  scale_fill_manual(
    name = NULL,
    values = c("Empirical" = "lightblue", 
               "sim_thr0ds-1op1soc0xp1sd0.25" = "bisque",
               "sim_thr0ds-5op5soc0xp1sd0.25" = "lightgreen" ),
    labels = c(
      "Empirical",
      "sim_thr0ds-1op1soc0xp1sd0.25" = "ß distance = -1\n ß opinion = 5",
      "sim_thr0ds-5op5soc0xp1sd0.25" = "ß distance = -5\n ß opinion = 5"
    ),
    guide = guide_legend(                 # ensure legend keys show the fill
      override.aes = list(shape = 21,     # a fillable shape in the legend
                          color = "black",
                          size = 3)
    )
  ) +
  scale_shape_manual(
    name = "Rankinit",
    values = c("-1"=25, "0"=22, "0.5"=21, "1"=24)
  ) +
  facet_wrap(~compscen) +
  labs(x = "avg time distance", y = "hospitalizations") +
  theme_bw() +
  theme(legend.position = "bottom", 
        legend.title = element_text(size = 13),
        legend.text = element_text(size = 13),
        strip.text = element_text(size = 14) ,
        axis.title.x = element_text(size = 14),
        axis.title.y = element_text(size = 14)) + guides(shape = "none")


pl_socmul <- sim_merge %>% mutate(compscen = factor(compscen,
                                                    levels = c("distance", "opinionxdistance", "socmult"),
                                                    labels = c("A: Effect distance",
                                                               "B: Distance X OwnOpinion",
                                                               "C: Social Multiplier")))%>%
  filter(compscen == "C: Social Multiplier") %>%
  group_by(compscen,condition, type, rankinit) %>%
  summarise(
    avgdist = mean(avgdist, na.rm = TRUE),
    cases   = mean(cases,   na.rm = TRUE),
    n_hospitals = n_distinct(hospital),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = avgdist, y = cases,
             fill = condition,                  # map fill to type
             shape = factor(rankinit))) +  # shapes 21–25 support fill
  geom_point(size = 3, color = "black", stroke = 0.6) +
  scale_x_continuous(
    limits = c(10, 35),       
    breaks = seq(10, 30, by = 10)
  ) +
  scale_fill_manual(
    name = NULL,
    values = c("Empirical" = "lightblue", 
               "sim_thr0ds-5op5soc1xp1sd0.25" = "bisque",
               "sim_thr0ds-5op5soc1xp0.5sd0.25" = "lightgreen" ),
    labels = c(
      "Empirical",
      "sim_thr0ds-5op5soc1xp1sd0.25" = "ß distance = -5\n ß opinion = 5\n w experience = 1",
      "sim_thr0ds-5op5soc1xp0.5sd0.25" = "ß distance = -5\n ß opinion = 5\n w experience = 0.5"
    ),
    breaks = c(
      "Empirical",
      "sim_thr0ds-5op5soc1xp1sd0.25" ,
      "sim_thr0ds-5op5soc1xp0.5sd0.25"
    ),
    guide = guide_legend(       
      position = "bottom",
      override.aes = list(shape = 21,    
                          color = "black",
                          size = 3)
    )
  ) +
  scale_shape_manual(
    name = "PNE rank",
    values = c("1"=24, "0.5"=21, "0"=22, "-1"=25),
    guide = guide_legend(position = "right"),
    breaks = c("1", "0.5", "0", "-1")
  ) +
  facet_wrap(~compscen) +
  labs(x = "avg time distance", y = "hospitalizations") +
  theme_bw() +
  theme(legend.title = element_text(size = 13),
        legend.text = element_text(size = 13),
        strip.text = element_text(size = 14) ,
        axis.title.x = element_text(size = 14),
        axis.title.y = element_text(size = 14))

comppic <- ggpubr::ggarrange(pl_dist,pl_distxop,pl_socmul,nrow = 1)
ggsave(comppic,file="experiments/comppic.jpg", width = 18, height = 6)


baselineemp %>%
  ggplot(aes(x = emp_avgdist, y = emp_cases,fill = as.factor(rankinit),label = name)) +
  geom_label_repel(
    size = 4, 
    max.overlaps = Inf) +
  xlab("average distance") +
  ylab("hospitalizations") + 
  scale_fill_manual(
    name = "PNE rank",
    values = c("1" = "lightgreen",
               "0.5" = "lightblue" ,
               "0" = "bisque",
               "-1" = "salmon"),
    breaks = c("1", "0.5", "0", "-1")
  ) +
  theme_bw() +
  theme(
    legend.position = "bottom",
    legend.title = element_text(size = 13),
    axis.title.x = element_text(size = 14),
    axis.title.y = element_text(size = 14)
  )
ggsave(file="empdist.jpg", width = 12, height = 6)
