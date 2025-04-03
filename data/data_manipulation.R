library(dplyr)
library(readxl)

setwd("C:/Users/rocpa/OneDrive/Documenti/GitHub/childbirthod/data/")

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

# 
osp <- read_excel("accessi_parto_ospedali.xlsx")
osp <- osp[,-6]
# write.csv(osp,"accessi_parto_ospedali_used.csv",row.names = F)

osp <- osp %>% group_by(presidio) %>% mutate(totparti = sum(parti))

# matrice distanze

distcounsel <- read.csv("matrice_distanze_consultori.csv",sep="," , check.names = FALSE) 
names(distcounsel)[1] <- "womencom"
# to test: first element is municipality woman, second is municipality counselcenter
distcounsel[distcounsel$womencom == "51041","49007"]

disthospital <- read.csv("matrice_distanze_ospedali.csv",sep="," , check.names = FALSE) 
names(disthospital)[1] <- "womencom"
# to test: first element is municipality woman, second is municipality hospital
disthospital[disthospital$womencom == "51041","49014"]

# distall <- cbind(distcounsel,disthospital)
distall <- read.csv("matrice_distanze_all.csv",sep="," , check.names = FALSE)
distall[distall$womencom == "48049","52037"]







