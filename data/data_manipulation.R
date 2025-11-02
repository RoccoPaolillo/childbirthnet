library(dplyr)
library(readxl)
library(readr)
library(tidyr)
library(tidyverse)
library(ggplot2)
library(ggrepel)


setwd("C:/Users/LENOVO/Documents/GitHub/childbirthod/data/")

ricoveriparti2023 <- read.csv("ricoveri_parti_2023.csv",sep=",")

# consultori
cons2019 <- read.csv("elenco_consultori_2019.csv",sep=";")
cons2019 <- cons2019 %>% mutate(Comune = trimws(Comune))  %>%
  mutate(Codice.struttura = trimws(Codice.struttura))
table(cons2019$Codice.struttura)[table(cons2019$Codice.struttura) > 1]

cons2019[cons2019$Codice.struttura == "10012D" & cons2019$Comune == "CAMAIORE", ]$Codice.struttura <- "10012DCA"
cons2019[cons2019$Codice.struttura == "02002D" & cons2019$Comune == "LAMPORECCHIO", ]$Codice.struttura <- "02002DLA"
cons2019[cons2019$Codice.struttura == "21012D" & cons2019$Comune == "SCANDICCI", ]$Codice.struttura <- "21012DSC"
cons2019[cons2019$Codice.struttura == "22212D" & cons2019$Comune == "CASTELFRANCO DI SOTTO", ]$Codice.struttura <- "22212DCS"
cons2019[cons2019$Codice.struttura == "31012D" & cons2019$Comune == "REGGELLO", ]$Codice.struttura <- "31012DRE"

cons2019_used <- cons2019 %>% select(Codice.Comune,Codice.struttura)

# write.csv(cons2019_used,"elenco_consultori_2019_used.csv",row.names = F)

# filtered consultori

cons2019used188 <- read.csv("elenco_consultori_2019_used.csv",sep=",")
cons2019_48 <- read_excel("elenco_consultori_2019_XLS.xlsx") %>% filter(main == "X")

cons2019_48[cons2019_48$`Codice struttura` == "10012D" & cons2019_48$Comune == "CAMAIORE", ]$`Codice struttura` <- "10012DCA"
cons2019_48[cons2019_48$`Codice struttura` == "02002D" & cons2019_48$Comune == "LAMPORECCHIO", ]$`Codice struttura` <- "02002DLA"
cons2019_48[cons2019_48$`Codice struttura` == "21012D" & cons2019_48$Comune == "SCANDICCI", ]$`Codice struttura`<- "21012DSC"
cons2019_48[cons2019_48$`Codice struttura` == "22212D" & cons2019_48$Comune == "CASTELFRANCO DI SOTTO", ]$`Codice struttura` <- "22212DCS"
cons2019_48[cons2019_48$`Codice struttura` == "31012D" & cons2019_48$Comune == "REGGELLO", ]$`Codice struttura` <- "31012DRE"

cons2019filtered <- cons2019used188 %>% filter(Codice.struttura %in% cons2019_48$`Codice struttura`)

write.csv(cons2019filtered,"elenco_consultori_2019FILTERED_used.csv",row.names = F)

# 
osp <- read_excel("accessi_parto_ospedali.xlsx")
osp <- osp[,-6]
# write.csv(osp,"accessi_parto_ospedali_used.csv",row.names = F)

osp <- osp %>% group_by(presidio) %>% mutate(totparti = sum(parti))

# matrice distanze

distcounsel <- read.csv("matrice_distanze_consultori.csv",sep="," , check.names = FALSE) 
names(distcounsel)[1] <- "womencom"
# to test: first element is municipality woman, second is municipality counselcenter
distcounsel[distcounsel$womencom == as.character(53001),"100007"]
df_normalized[df_normalized$womencom == "53001","100007"]


#disthospital <- read.csv("matrice_distanze_ospedali.csv",sep="," , check.names = FALSE) 
#names(disthospital)[1] <- "womencom"
# to test: first element is municipality woman, second is municipality hospital
# disthospital[disthospital$womencom == "51035","49014"]

# test that distcounsel already contains disthospital

unique(levels(as.factor(names(disthospital)  %in% names(distcounsel))))
unique(levels(as.factor(names(distcounsel)  %in% names(disthospital))))

cols_to_exclude <- c("womencom")

numeric_data <- distcounsel[ , !(names(distcounsel) %in% cols_to_exclude)]

global_min <- min(as.matrix(numeric_data), na.rm = TRUE)
global_max <- max(as.matrix(numeric_data), na.rm = TRUE)

normalize_global <- function(x) {
  if (is.numeric(x)) (x - global_min) / (global_max - global_min) else x
}

df_normalized <- distcounsel
df_normalized[ , !(names(distcounsel) %in% cols_to_exclude)] <- lapply(
  distcounsel[ , !(names(distcounsel) %in% cols_to_exclude)],
  normalize_global
)

write.csv(df_normalized, file = "normalized_distance.csv",row.names = F)
df_normalized <- read.csv("normalized_distance.csv",sep =",", check.names = FALSE)

# to put all distances into one vector and identify median

dfvect <- distcounsel[,-1]
if (!is.numeric(dfvect[[1]])) {
  rn <- dfvect[[1]]
  df <- dfvect[-1]
} else rn <- NULL

# keep only numeric columns and coerce
num <- as.data.frame(lapply(dfvect, function(x) as.numeric(as.character(x))),
                     stringsAsFactors = FALSE)

# 1) ALL values flattened into one vector (including diagonal)
v_all <- as.numeric(as.matrix(num))


# resize mobilities

df_mob <- read.csv("accessi_parto_ospedali_used.csv",sep=",")
# value <= 3 is imposed as 1
#df_mob$res_15 <- ifelse(df_mob$parti > 3, round(df_mob$parti * 0.15), 1 )
df_mob$rankinit <- NA
df_mob[df_mob$presidio == "AREA ARETINA NORD AREZZO",]$rankinit <- 1
df_mob[df_mob$presidio == "COMPLESSO OSPEDALIERO CAREGGI - CTO (FI)",]$rankinit <- 1
df_mob[df_mob$presidio == "OSP. RIUNITI DELLA VAL DI CHIANA",]$rankinit <- -1
df_mob[df_mob$presidio == "NUOVO OSPEDALE BORGO S.LORENZO (FI)",]$rankinit <- -1
df_mob[df_mob$presidio == "SS. GIACOMO E CRISTOFORO MASSA",]$rankinit <- 0.5
df_mob[df_mob$presidio == "OSPEDALI PISANI (PI)",]$rankinit <- 1
df_mob[df_mob$presidio == "S.GIOVANNI DI DIO-TORREGALLI (FI)",]$rankinit <- 1
df_mob[df_mob$presidio == "CIVILE CECINA (LI)",]$rankinit <- 0.5
df_mob[df_mob$presidio == "OSPEDALE S. GIUSEPPE",]$rankinit <- 0.5
df_mob[df_mob$presidio == "OSPEDALE UNICO \"VERSILIA\"",]$rankinit <- 0
df_mob[df_mob$presidio == "CIVILE ELBANO PORTOFERRAIO (LI)",]$rankinit <- -1
df_mob[df_mob$presidio == "SERRISTORI FIGLINE V.A. (FI)",]$rankinit <- -1
df_mob[df_mob$presidio == "OSPEDALE DEL VALDARNO - \"S.MARIA DELLA GRUCCIA\"",]$rankinit <- -1
df_mob[df_mob$presidio == "LE SCOTTE SIENA",]$rankinit <- 0.5
df_mob[df_mob$presidio == "MISERICORDIA GROSSETO",]$rankinit <- 0
df_mob[df_mob$presidio == "OSPEDALE DELL'ALTA VAL D'ELSA POGGIBONSI",]$rankinit <- 0.5
df_mob[df_mob$presidio == "S.M. ANNUNZIATA BAGNO A RIPOLI",]$rankinit <- 0
df_mob[df_mob$presidio == "RIUNITI LIVORNO",]$rankinit <- 0.5
df_mob[df_mob$presidio == "NUOVO OSPEDALE DI PRATO S.STEFANO",]$rankinit <- 1
df_mob[df_mob$presidio == "OSPEDALE SAN JACOPO",]$rankinit <- 1
df_mob[df_mob$presidio == "F.LOTTI PONTEDERA (PI)",]$rankinit <- 0.5
df_mob[df_mob$presidio == "SAN ROSSORE",]$rankinit <- 0 # non classificato come pochi
df_mob[df_mob$presidio == "OSPEDALE SAN LUCA",]$rankinit <- 0
df_mob[df_mob$presidio == "S. FRANCESCO BARGA (LU)",]$rankinit <- -1

##

ranking_hospitals <- df_mob %>% select("presidio","rankinit")
ranking_hospitals <- ranking_hospitals[!duplicated(ranking_hospitals), ]
write.csv(ranking_hospitals,"ranking_hospitals.csv",row.names = F)

#write.csv(df_mob,"accessi_parto_ospedali_used.csv",row.names = F)

# editing figures

library(magick)
setwd("C:/Users/rocpa/OneDrive/Documenti/GitHub/childbirthod/")

img <- image_read("landscape.jpeg")

# Write it as an EPS file
image_write(img, path = "landscape.eps", format = "eps")

# outcome
setwd("C:/Users/LENOVO/Documents/GitHub/childbirthod/experiments/genova_firstrun")

files <- sort(list.files( pattern = "\\.csv$", full.names = TRUE))

all_data <- do.call(rbind, lapply(seq_along(files), function(i) {
  x <- read.csv(files[i], stringsAsFactors = FALSE)
  x$run  <- i
  x$file <- basename(files[i])
  x
}))

# to check that "who" of women always alignt with one pair pro_com, selectedhospitalemp
who_with_conflicts <- all_data %>%
  group_by(who) %>%
  summarise(
    n_pairs = n_distinct(pro_com, selectedhospitalemp),
    pairs   = paste0(
      unique(paste0("(", pro_com, ",", selectedhospitalemp, ")")), 
      collapse = "; "
    ),
    .groups = "drop"
  ) %>%
  filter(n_pairs > 1)

who_with_conflicts

map_hosp <- read.csv("C:/Users/LENOVO/Documents/GitHub/childbirthod/data/mapping_hospitals.csv",sep=";")

all_data <- merge(all_data,map_hosp, by = c())


write.csv(all_data,file="dataset_gefirstrun.csv",row.names = F)

############## upload data new genova

path <- "genova_96/"
files <- list.files(path, pattern = ".csv$", full.names = TRUE)

combined_df <- files %>%
  set_names() %>%                             # keep filenames as names
  imap_dfr(~ read_csv(.x))  # add cond_n as progressive number

combined_df <- combined_df %>%
  dplyr::group_by(
    rescale15, initrankrnd, initrank_sd, distance_threshold, n_network,
    weight_distance_hospital, weight_opinion, social_multiplier,
    weight_experience, uptrnk_sd, eps_birthtrue, eps_notbirth,
    mu_birthtrue, mu_notbirth
  ) %>%
  dplyr::mutate(condition = dplyr::cur_group_id()) %>%
  dplyr::ungroup()

combined_df <- combined_df %>% select(condition, everything())

df_summary <- combined_df %>%
  group_by(condition) %>%
  summarise(n = n()) %>%
  arrange(condition)

######################

parse_netlogo_table <- function(s, suffix) {
  if (is.na(s) || !nzchar(s)) return(setNames(numeric(0), character(0)))
  # strip wrappers
  s <- str_remove(s, "^\\{\\{table:\\s*")
  s <- str_remove(s, "\\}\\}\\s*$")
  
  # capture [ key  value ] where key may be "48.0" or 48
  pairs <- str_match_all(
    s,
    "\\[\\s*\"?(-?\\d+(?:\\.\\d+)?)\"?\\s+(-?\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?)\\s*\\]"
  )[[1]]
  if (nrow(pairs) == 0) return(setNames(numeric(0), character(0)))
  
  # keys as numeric to normalize (so "48.0" -> 48), then to character without trailing .0
  keys_num <- as.numeric(pairs[, 2])
  # If a key fails to parse (unlikely here), fall back to the raw string
  keys_chr <- ifelse(
    is.na(keys_num),
    pairs[, 2],
    sub("\\.0+$", "", format(keys_num, trim = TRUE, scientific = FALSE))
  )
  
  vals <- as.numeric(pairs[, 3])
  
  # sort by numeric key so columns come out in ascending order
  ord <- order(suppressWarnings(as.numeric(keys_chr)))
  setNames(vals[ord], paste0(keys_chr[ord], "_", suffix))
}

# Helper to expand ONE source column into many wide columns
expand_table_column <- function(df, col, suffix) {
  col <- rlang::ensym(col)
  df %>%
    mutate(.expanded = map(!!col, ~ parse_netlogo_table(.x, suffix))) %>%
    unnest_wider(.expanded, names_repair = "check_unique")
}

# ---- Apply to your data ----
# Assuming your data is in `combined_df`
# pricechoicelist -> *_prechoice
# rankinglist     -> *_rankinglist
combined_dfwide <- combined_df %>%
  expand_table_column(prechoicelist, "prechoicelist") %>%
  expand_table_column(rankinglist, "rankinglist")

# Put *_prechoice columns together, then *_rankinglist; keep all other cols first
derived_pre  <- grep("_(prechoicelist|prechoicelist)$", names(combined_dfwide), value = TRUE)
derived_rank <- grep("_rankinglist$",               names(combined_dfwide), value = TRUE)
base_cols    <- setdiff(names(combined_dfwide), c(derived_pre, derived_rank))

combined_dfwide <- combined_dfwide %>%
  select(all_of(base_cols), all_of(derived_pre), all_of(derived_rank))

combined_dfwide <- df2



load("combined_dfwide.Rdata")

### barplot

combined_dfwide$rankinit <- NA
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "AREA ARETINA NORD AREZZO",]$rankinit <- 1
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSPEDALE DEL VALDARNO - \"S.MARIA DELLA GRUCCIA\"",]$rankinit <- -1
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "COMPLESSO OSPEDALIERO CAREGGI - CTO (FI)",]$rankinit <- 1
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "LE SCOTTE SIENA",]$rankinit <- 0.5
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSP. RIUNITI DELLA VAL DI CHIANA",]$rankinit <- -1
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "MISERICORDIA GROSSETO",]$rankinit <- 0
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "NUOVO OSPEDALE BORGO S.LORENZO (FI)",]$rankinit <- -1
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSPEDALE DELL'ALTA VAL D'ELSA POGGIBONSI",]$rankinit <- 0.5
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "SS. GIACOMO E CRISTOFORO MASSA",]$rankinit <- 0.5
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "S.M. ANNUNZIATA BAGNO A RIPOLI",]$rankinit <- 0
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSPEDALI PISANI (PI)",]$rankinit <- 1
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "RIUNITI LIVORNO",]$rankinit <- 0.5
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "S.GIOVANNI DI DIO-TORREGALLI (FI)",]$rankinit <- 1
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "NUOVO OSPEDALE DI PRATO S.STEFANO",]$rankinit <- 1
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "CIVILE CECINA (LI)",]$rankinit <- 0.5
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSPEDALE SAN JACOPO",]$rankinit <- 1
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSPEDALE S. GIUSEPPE",]$rankinit <- 0.5
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "F.LOTTI PONTEDERA (PI)",]$rankinit <- 0.5
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSPEDALE UNICO \"VERSILIA\"",]$rankinit <- 0
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "SAN ROSSORE",]$rankinit <- 0
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "CIVILE ELBANO PORTOFERRAIO (LI)",]$rankinit <- -1
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "OSPEDALE SAN LUCA",]$rankinit <- 0
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "SERRISTORI FIGLINE V.A. (FI)",]$rankinit <- -1
combined_dfwide[combined_dfwide$name_selectedhospitalemp == "S. FRANCESCO BARGA (LU)",]$rankinit <- -1

combined_dfwide <- combined_dfwide %>%
  rowwise() %>%
  mutate(
    distemp = {
      x <- as.character(pro_com)
      y <- as.character(procom_selectedhospitalemp)
      val <- distcounsel[distcounsel$womencom == x, y]
    }
  ) %>%
  ungroup()

combined_dfwide <- combined_dfwide %>%
  rowwise() %>%
  mutate(
    distsim = {
      x <- as.character(pro_com)
      y <- as.character(procom_selectedhospital)
      val <- distcounsel[distcounsel$womencom == x, y]
    }
  ) %>%
  ungroup()

combined_dfwide <- combined_dfwide %>%
  rowwise() %>%
  mutate(
    distempnorm = {
      x <- as.character(pro_com)
      y <- as.character(procom_selectedhospitalemp)
      val <- df_normalized[df_normalized$womencom == x, y]
    }
  ) %>%
  ungroup()

combined_dfwide <- combined_dfwide %>%
  rowwise() %>%
  mutate(
    distsimnorm = {
      x <- as.character(pro_com)
      y <- as.character(procom_selectedhospital)
      val <- df_normalized[df_normalized$womencom == x, y]
    }
  ) %>%
  ungroup()

save(combined_dfwide,file="combined_dfwide.Rdata")

### analysis

load("combined_dfwide.Rdata")

# To have a list of match cases simulation - empiric
# combined_dfwide$match <- ifelse(combined_dfwide$selectedhospital == combined_dfwide$selectedhospitalemp,1,0)
# 
# ratio_df <- combined_dfwide %>%
#   group_by(condition) %>%
#   summarise(
#     match_sum = sum(match, na.rm = TRUE),
#     match_ratio = match_sum / 20177,
#     weight_distance_hospital = unique(weight_distance_hospital),
#     weight_opinion = unique(weight_opinion),
#     social_multiplier = unique(social_multiplier),
#     weight_experience = unique(weight_experience),
#     uptrnk_sd = unique(uptrnk_sd),
#     distance_threshold = unique(distance_threshold)
#   )
# 
# by_rank <- combined_dfwide %>%
#   group_by(condition) %>%
#   mutate(n_in_condition = n()) %>%                 # total rows in this condition
#   group_by(condition, rankinit) %>%
#   summarise(
#     n_in_rank      = n(),                          # rows in this condition×rank
#     matches_in_rank = sum(match, na.rm = TRUE),    # matched rows in this condition×rank
#     n_in_condition = first(n_in_condition),
#     .groups = "drop_last"
#   ) %>%
#   mutate(
#     # your requested ratio: divide matches by all occurrences within the condition
#     ratio_match_over_condition = matches_in_rank / n_in_condition,
#     # (optional) matches divided by occurrences within the rank (often useful too)
#     ratio_match_within_rank    = matches_in_rank / n_in_rank
#   ) %>%
#   ungroup()
# 
# ratio_rk <- combined_dfwide %>%
#   group_by(rankinit) %>%
#   summarise(
#     match_sum = sum(match, na.rm = TRUE),
#     match_ratio = match_sum / 20177,
#     weight_distance_hospital = weight_distance_hospital,
#     weight_opinion =  weight_opinion,
#     social_multiplier = social_multiplier,
#     weight_experience = weight_experience,
#     uptrnk_sd = uptrnk_sd,
#     distance_threshold = distance_threshold
#   )
# 
# # Join back into the original dataset
# combined_dfwide <- combined_dfwide %>%
#   left_join(ratio_df, by = c("condition","weight_distance_hospital","weight_opinion","social_multiplier","weight_experience","uptrnk_sd","distance_threshold" ))


# condition 25
baselineemp <- combined_dfwide %>% filter(distance_threshold == 0 & weight_distance_hospital == -1 & weight_opinion == 0 & 
                                            social_multiplier == 0 & weight_experience == 0.5 & uptrnk_sd == 0) %>%
  group_by(selectedhospitalemp) %>%
  summarise(
    emp_cases = n(),
    emp_avgdist = mean(distemp, na.rm = TRUE),
    condition = unique(condition),
    rankinit = unique(rankinit),
    name = unique(name_selectedhospitalemp)
  ) %>%
  rename(hospital = selectedhospitalemp)

# condition 25
sim_dist1 <- combined_dfwide %>% filter(distance_threshold == 0 & weight_distance_hospital == -1 & weight_opinion == 0 & 
                                            social_multiplier == 0 & weight_experience == 0.5 & uptrnk_sd == 0) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

# condition 1
sim_dist5 <- combined_dfwide %>% filter(distance_threshold == 0 & weight_distance_hospital == -5 & weight_opinion == 0 & 
                                          social_multiplier == 0 & weight_experience == 0.5 & uptrnk_sd == 0) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

# condition 9
sim_dist5op1 <- combined_dfwide %>% filter(distance_threshold == 0 & weight_distance_hospital == -5 & weight_opinion == 1 & 
                                          social_multiplier == 0 & weight_experience == 0.5 & uptrnk_sd == 0) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

# condition 17
sim_dist5op5 <- combined_dfwide %>% filter(distance_threshold == 0 & weight_distance_hospital == -5 & weight_opinion == 5 & 
                                             social_multiplier == 0 & weight_experience == 0.5 & uptrnk_sd == 0) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

# condition 21
sim_dist5op5soc1exp05 <- combined_dfwide %>% filter(distance_threshold == 0 & weight_distance_hospital == -5 & weight_opinion == 5 & 
                                             social_multiplier == 1 & weight_experience == 0.5 & uptrnk_sd == 0) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

# condition 23
sim_dist5op5soc1exp1 <- combined_dfwide %>% filter(distance_threshold == 0 & weight_distance_hospital == -5 & weight_opinion == 5 & 
                                                      social_multiplier == 1 & weight_experience == 1 & uptrnk_sd == 0) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

# condition 69
sim_dist5op5soc1exp05thr260 <- combined_dfwide %>% filter(distance_threshold == 260 & weight_distance_hospital == -5 & weight_opinion == 5 & 
                                                      social_multiplier == 1 & weight_experience == 0.5 & uptrnk_sd == 0) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

# condition 71
sim_dist5op5soc1exp1thr260 <- combined_dfwide %>% filter(distance_threshold == 260 & weight_distance_hospital == -5 & weight_opinion == 5 & 
                                                     social_multiplier == 1 & weight_experience == 1 & uptrnk_sd == 0) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

sim_dist5op5soc1exp1thr260updr25 <- combined_dfwide %>% filter(distance_threshold == 260 & weight_distance_hospital == -5 & weight_opinion == 5 & 
                                                           social_multiplier == 1 & weight_experience == 1 & uptrnk_sd == 0.25) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

sim_dist5op5soc1exp1thr0updr25 <- combined_dfwide %>% filter(distance_threshold == 0 & weight_distance_hospital == -5 & weight_opinion == 5 & 
                                                                 social_multiplier == 1 & weight_experience == 1 & uptrnk_sd == 0.25) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

sim_dist1op5soc1exp1thr0updr25 <- combined_dfwide %>% filter(distance_threshold == 0 & weight_distance_hospital == -1 & weight_opinion == 5 & 
                                                               social_multiplier == 1 & weight_experience == 1 & uptrnk_sd == 0.25) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

sim_dist1op5soc1exp05thr0updr25 <- combined_dfwide %>% filter(distance_threshold == 0 & weight_distance_hospital == -1 & weight_opinion == 5 & 
                                                               social_multiplier == 1 & weight_experience == 0.5 & uptrnk_sd == 0.25) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)
  
sim_dist1op5soc1exp05thr260updr25 <- combined_dfwide %>% filter(distance_threshold == 260 & weight_distance_hospital == -1 & weight_opinion == 5 & 
                                                                social_multiplier == 1 & weight_experience == 0.5 & uptrnk_sd == 0.25) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

sim_dist1op5soc1exp1thr260updr25 <- combined_dfwide %>% filter(distance_threshold == 260 & weight_distance_hospital == -1 & weight_opinion == 5 & 
                                                                  social_multiplier == 1 & weight_experience == 1 & uptrnk_sd == 0.25) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

sim_dist5op5soc0exp1thr260updr0 <- combined_dfwide %>% filter(distance_threshold == 260 & weight_distance_hospital == -5 & weight_opinion == 5 & 
                                                                 social_multiplier == 0 & weight_experience == 1 & uptrnk_sd == 0) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

sim_dist5op1soc1exp1thr0updr0 <- combined_dfwide %>% filter(distance_threshold == 0 & weight_distance_hospital == -5 & weight_opinion == 1 & 
                                                                 social_multiplier == 1 & weight_experience == 1 & uptrnk_sd == 0) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)

sim_dist5op1soc1exp1thr260updr0 <- combined_dfwide %>% filter(distance_threshold == 260 & weight_distance_hospital == -5 & weight_opinion == 1 & 
                                                              social_multiplier == 1 & weight_experience == 1 & uptrnk_sd == 0) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)


sim_dist1op5soc1exp05thr0updr0 <- combined_dfwide %>% filter(distance_threshold == 0 & weight_distance_hospital == -1 & weight_opinion == 5 & 
                                                                social_multiplier == 1 & weight_experience == 0.5 & uptrnk_sd == 0) %>%
  group_by(selectedhospital) %>%
  summarise(
    sim_cases = n(),
    sim_avgdist = mean(distsim, na.rm = TRUE),
    condition = unique(condition),
    name = unique(name_selectedhospital)
  ) %>%
  rename(hospital = selectedhospital)





mergelong <- function(t) 
  {baselineemp %>%
  full_join(t, by = c("hospital","name"))%>%
  pivot_longer(
    cols = c(emp_cases, sim_cases, emp_avgdist, sim_avgdist),
    names_to = c("type", ".value"),
    names_pattern = "^(emp_|sim_)(.*)$"
  ) %>%
  mutate(
    type = recode(type,
                  "emp_" = "Empirical",
                  "sim_" = "Simulated")
  )
}

bas_simdist1 <- mergelong(sim_dist1)
bas_simdist5 <- mergelong(sim_dist5)
bas_simdist5op1 <- mergelong(sim_dist5op1)
bas_simdist5op5 <- mergelong(sim_dist5op5)
bas_simdist5op5soc1exp05 <- mergelong(sim_dist5op5soc1exp05)
bas_simdist5op5soc1exp05thr260 <- mergelong(sim_dist5op5soc1exp05thr260)
bas_simdist5op5soc1exp1 <- mergelong(sim_dist5op5soc1exp1)
bas_simdist5op5soc1exp1thr260 <- mergelong(sim_dist5op5soc1exp1thr260)
bas_sim_dist5op5soc1exp1thr260updr25 <- mergelong(sim_dist5op5soc1exp1thr260updr25)
bas_sim_dist5op5soc1exp1thr0updr25 <- mergelong(sim_dist5op5soc1exp1thr0updr25)
bas_sim_dist1op5soc1exp1thr0updr25 <- mergelong(sim_dist1op5soc1exp1thr0updr25)
bas_sim_dist1op5soc1exp05thr0updr25 <- mergelong(sim_dist1op5soc1exp05thr0updr25)
bas_sim_dist1op5soc1exp05thr260updr25 <- mergelong(sim_dist1op5soc1exp05thr260updr25)
bas_sim_dist1op5soc1exp1thr260updr25 <- mergelong(sim_dist1op5soc1exp1thr260updr25)
bas_sim_dist5op5soc0exp1thr260updr25 <- mergelong(sim_dist5op5soc0exp1thr260updr25)
bas_sim_dist5op1soc1exp1thr0updr0 <- mergelong(sim_dist5op1soc1exp1thr0updr0)
bas_sim_dist1op5soc1exp05thr0updr0 <- mergelong(sim_dist1op5soc1exp05thr0updr0)

bas_simdist1$comparison = 1
bas_simdist5$comparison = 2
bas_simdist5op1$comparison = 3
bas_simdist5op5$comparison = 4
bas_simdist5op5soc1exp05$comparison = 5
bas_simdist5op5soc1exp05thr260$comparison = 6
bas_simdist5op5soc1exp1$comparison = 7
bas_simdist5op5soc1exp1thr260$comparison = 8
bas_sim_dist5op5soc1exp1thr260updr25$comparison = 9
bas_sim_dist5op5soc1exp1thr0updr25$comparison = 10
bas_sim_dist1op5soc1exp1thr0updr25$comparison = 11
bas_sim_dist1op5soc1exp05thr0updr25$comparison = 12
bas_sim_dist1op5soc1exp05thr260updr25$comparison = 13
bas_sim_dist1op5soc1exp1thr260updr25$comparison = 14
bas_sim_dist5op5soc0exp1thr260updr25$comparison = 15
bas_sim_dist5op1soc1exp1thr0updr0$comparison = 16
bas_sim_dist1op5soc1exp05thr0updr0$comparison = 17

sim_merge <- rbind(
  
  bas_simdist1,
  bas_simdist5,
  bas_simdist5op1,
  bas_simdist5op5,
  bas_simdist5op5soc1exp05,
  bas_simdist5op5soc1exp05thr260,
  bas_simdist5op5soc1exp1,
  bas_simdist5op5soc1exp1thr260,
  bas_sim_dist5op5soc1exp1thr260updr25,
  bas_sim_dist5op5soc1exp1thr0updr25,
  bas_sim_dist1op5soc1exp1thr0updr25,
  bas_sim_dist1op5soc1exp05thr0updr25,
  bas_sim_dist1op5soc1exp05thr260updr25,
  bas_sim_dist1op5soc1exp1thr260updr25,
  bas_sim_dist5op5soc0exp1thr260updr25,
  bas_sim_dist5op1soc1exp1thr0updr0,
  bas_sim_dist1op5soc1exp05thr0updr0
)

sim_merge %>%
  group_by(comparison, type, rankinit) %>%
  summarise(
    avgdist = mean(avgdist, na.rm = TRUE),
    cases   = mean(cases,   na.rm = TRUE),
    n_hospitals = n_distinct(hospital),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = avgdist, y = cases,
             fill = type,                  # map fill to type
             shape = factor(rankinit))) +  # shapes 21–25 support fill
  geom_point(size = 3, color = "black", stroke = 0.6) +
  scale_fill_manual(
    name = "Type",
    values = c(Empirical = "lightblue", Simulated = "bisque"),
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
  facet_wrap(~comparison) +
  labs(x = "avg time distance", y = "hospitalizations") +
  theme_bw()


# OD

df <- combined_dfwide %>% select(condition,timeatbirth,ends_with("_prechoicelist")) %>%
  pivot_longer(
    cols = 3:26,  # all columns ending with those
    names_to = "hospital" ,
    values_to = "opinionrank"
  )

rank_map <- c(
  `48` = 1, `49` = -1, `50` = 1,  `51` = 0.5, `52` = -1, `53` = 0,
  `54` = -1, `55` = 0.5, `56` = 0.5, `57` = 0,  `58` = 1,
  `59` = 0.5, `60` = 1,  `61` = 1,  `62` = 0.5, `63` = 1,
  `64` = 0.5, `65` = 0.5, `66` = 0,  `67` = 0,  `68` = -1,
  `69` = 0,  `70` = -1, `71` = -1
)

df <- df %>%
  mutate(
    code      = str_remove(hospital, "_prechoicelist$"),   # "49_prechoicelist" -> "49"
    origrank  = as.numeric(rank_map[code])
  ) %>%
  select(-code)  # drop helper if you like


df %>%
  filter(condition == 23) %>%
  group_by(timeatbirth, origrank) %>%
  summarise(avg_rank = mean(opinionrank, na.rm = TRUE), .groups = "drop") %>%
  filter(timeatbirth %in% seq(0,20177,1000)) %>%
  ggplot(aes(x = timeatbirth, y = avg_rank, color = as.factor(origrank), group = origrank)) +
  geom_line() +
  geom_point(size = 1.5) +
  theme_bw() +
  labs(x = "Time at birth", y = "Average opinion rank", color = "Original rank")


df %>%
  filter(condition == 23 & hospital == "50_prechoicelist") %>%
  filter(timeatbirth %in% seq(0,20177,1000)) %>%
  ggplot(aes(x = timeatbirth, y = opinionrank)) +
  geom_line() +
  geom_point(size = 1.5) +
  theme_bw()


careggi <- combined_dfwide %>% filter(selectedhospital == 50) %>% select(condition, who, timeatbirth, pro_com,
                                                                         selectedhospitalemp,name_selectedhospitalemp,
                                                                         procom_selectedhospitalemp,selectedhospital,
                                                                         name_selectedhospital,procom_selectedhospital,
                                                                         rankinglist,`50_prechoicelist`)


careggi %>% filter(condition == 23 & pro_com == 48025) %>%
  group_by(timeatbirth, pro_com) %>%
  summarise(avg_rank = mean(`50_prechoicelist`, na.rm = TRUE), .groups = "drop") %>%
#  filter(timeatbirth %in% seq(0,20177,1000)) %>%
  ggplot(aes(x = timeatbirth, y = avg_rank, color = as.factor(pro_com))) +
  geom_line() +
  geom_point(size = 1.5) +
  theme_bw() +
  labs(x = "Time at birth", y = "Average opinion rank", color = "Original rank")






