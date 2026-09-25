# Author : MBE
# Date   : 2026-09-25
#
# Purpose:
#   Generate the tumor/normal pairing file "variant_call_list_TvN.tsv",
#   used as input for the GeSA pipeline.
#
# Output format:
#   - Tab-separated, no header (unless required by GeSA)
#   - Column 1: tumor sample ID
#   - Column 2: matched normal sample ID


library(dplyr)

wes_PDX_heatly        <- "C:/Users/ma_bertrand/Desktop/P025/sequenza_investigation_2025/PDX/WES_PDX_annotation.csv"
out_file <- "C:/Users/ma_bertrand/Desktop/P025/sequenza_investigation_2025/PDX/variant_call_list_TvN.tsv"


wes <- read.table(wes_PDX_heatly, header = TRUE, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
colnames(wes) <- trimws(colnames(wes))


wes <- wes %>%
  mutate(sampleType = case_when(
    sampleType == "xenograft" ~ "WES_PDX",
    sampleType == "healthy"   ~ "WES_healthy",
    TRUE ~ NA_character_
  ))

wes_clean <- wes %>%
  rename(
    datasetID  = datasetId,
    patient_id = `MAPPYACTS inclusion number`  ) %>%
  dplyr::select(datasetID, sampleType, patient_id)


# Tumors (PDX)
tumors <- wes_clean %>%
  filter(sampleType == "WES_PDX") %>%
  select(patient_id, tumor_id = datasetID)

# healthy
normals <- wes_clean %>%
  filter(sampleType == "WES_healthy") %>%
  select(patient_id, normal_id = datasetID)

# Pairs tumeur / normal per patient
pairs <- inner_join(tumors, normals, by = "patient_id",
                    relationship = "many-to-many")

# Check
tumors_without_normal <- anti_join(tumors, normals, by = "patient_id") #MAP223
normals_without_tumor <- anti_join(normals, tumors, by = "patient_id")
patients_multi_normal <- normals %>% count(patient_id) %>% filter(n > 1)

message(nrow(pairs), " tumor/normal pairs created")
message(nrow(tumors_without_normal), " PDX samples without a matched normal")
message(nrow(normals_without_tumor), " normal samples without a matched PDX")
message(nrow(patients_multi_normal), " patients with multiple normal samples")



# ---
write.table(pairs %>% select(tumor_id, normal_id),
            file = out_file,
            sep = "\t", 
            quote = FALSE,
            row.names = FALSE, 
            col.names = FALSE)
