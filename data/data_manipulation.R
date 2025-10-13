library(dplyr)
library(readxl)

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
distcounsel[distcounsel$womencom == "53001","100007"]
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
setwd("C:/Users/LENOVO/Documents/GitHub/childbirthod/data_bs/")

files <- sort(list.files( pattern = "\\.csv$", full.names = TRUE))

all_data <- do.call(rbind, lapply(seq_along(files), function(i) {
  x <- read.csv(files[i], stringsAsFactors = FALSE)
  x$run  <- i
  x$file <- basename(files[i])
  x
}))

write.csv(all_data,file="test_multipleruns.csv",row.names = F)
