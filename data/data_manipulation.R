library(dplyr)
library(readxl)

setwd("C:/Users/rocpa/OneDrive/Documenti/GitHub/childbirthod/data/")

cons2019 <- read.csv("elenco_consultori_2019.csv",sep=";")
osp <- read_excel("accessi_parto_ospedali.xlsx")