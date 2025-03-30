library(dplyr)
library(readxl)

setwd("C:/Users/rocpa/OneDrive/Documenti/GitHub/childbirthod/data/")

ricoveriparti2023 <- read.csv("ricoveri_parti_2023.csv",sep=",")
osp <- read_excel("accessi_parto_ospedali.xlsx")
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
