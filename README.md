# Forensic ELA & Local SQNR Analysis in MATLAB

![MATLAB](https://img.shields.io/badge/MATLAB-Data_Analysis-blue)

## Descrizione del Progetto
Questo progetto unisce le nozioni di elaborazione dei segnali multimediali all'ambito della Digital Forensics. L'obiettivo principale è lo sviluppo di un algoritmo proprietario in ambiente MATLAB (modalità *white-box*) capace di rilevare manipolazioni digitali (fotomontaggi) sfruttando le incongruenze negli artefatti di compressione JPEG. 

Invece di affidarsi a software commerciali a scatola chiusa, questo tool analizza il residuo di quantizzazione spaziale, l'analisi del Rapporto Segnale/Rumore di Quantizzazione (SQNR) in finestre locali, e l'ispezione in frequenza mediante Trasformata Discreta del Coseno (DCT). Il risultato è una heatmap energetica che isola le regioni dell'immagine con una "storia di compressione" differente.

## Fondamenti Teorici


**Spazio Colore YCbCr:** L'algoritmo isola e lavora esclusivamente sul canale della Luminanza (Y), il quale preserva la mappatura strutturale più fedele degli artefatti di quantizzazione JPEG rispetto ai canali di crominanza.
**Compressione JPEG e Quantizzazione:** Quando si crea un fotomontaggio, la parte incollata reagisce alla nuova compressione in modo diverso rispetto allo sfondo originale, accumulando un errore di quantizzazione asimmetrico.
**SQNR Locale:** La metrica fondamentale per valutare l'anomalia è la differenza di energia del rumore tra un blocco di controllo e l'area sospetta.

La formula matematica dell'SQNR utilizzata è la seguente:

$$SQNR_{dB}=10 \log_{10}\left(\frac{P_{segnale}}{P_{rumore}}\right)$$

Mentre il distacco matematico tra l'area manipolata e il contesto originale è quantificato dal Delta SQNR Locale:

$$\Delta SQNR_{locale}=|SQNR_{sfondo}-SQNR_{sospetto}|$$

## Metodologia e Pipeline

L'algoritmo si articola in sei fasi automatizzate:
1.  **Pre-processing ed Estrazione Luminanza:** Conversione da RGB a YCbCr ed estrazione della matrice float del canale Y.
2.  **Ricompressione (Stress-Test):** Salvataggio temporaneo a una qualità JPEG fissa (es. 90%) per catalizzare l'errore e calcolo della differenza assoluta (residuo) tra originale e ricompressa.
3.  **Filtraggio Spaziale:** Applicazione in cascata di un Filtro Mediano (3x3) per rimuovere il rumore impulsivo e di un Filtro Gaussiano per generare una mappa di densità termica (Heatmap).
4.  **Rilevamento e Allineamento JPEG:** Ricerca automatica del picco di energia massima e calcolo rigoroso dell'allineamento alla griglia standard 8x8 del file JPEG.
5.  **Analisi SQNR Locale:** Calcolo del differenziale $\Delta SQNR$ per comprovare empiricamente l'appartenenza dei blocchi a storie di compressione opposte (solitamente con scarti >10-15 dB).
6.  **Analisi Spettrale (Firma DCT):** Estrazione della Trasformata Discreta del Coseno 2D sul blocco sospetto per validare l'incongruenza spettrale.

## Esecuzione e Dashboard Forense

Per eseguire l'analisi, avviare lo script principale su MATLAB avendo cura di posizionare un'immagine di test nella cartella `dataset/`.
L'esecuzione produce un **Report Forense Automatico** strutturato in pannelli:

![Dashboard Forense](inserisci_qui_il_percorso_della_tua_immagine_dashboard.png)
*(Esempio: L'elevato valore di energia in rosso evidenzia matematicamente la presenza dell'elemento estraneo incollato)*

* **Pannello 3 (ELA Raw):** Visualizzazione dell'amplificazione lineare dell'errore (fattore x40).
* **Pannello 4 (Heatmap Energetica):** Evidenzia il dislivello energetico certificando matematicamente il fotomontaggio tramite bounding box.
* **Pannello 5 (Firma DCT):** Conferma la presenza di energia anomala sulle componenti AC incompatibile con le aree circostanti.

## Analisi Critica e Limiti
**Ricompressione Distruttiva (Social Media):** L'inoltro tramite piattaforme come WhatsApp o Facebook applica una "pialla statistica" tramite una nuova gravosa matrice di quantizzazione globale, che sovrascrive le tracce originali annullando l'efficacia dell'ELA.
**Assenza di Alte Frequenze:** Nelle aree d'immagine completamente piatte (solo componente DC, assenza di bordi), il rumore di quantizzazione non si sviluppa in modo marcato, causando falsi negativi.

## Sviluppi Futuri
Implementazione di una Graphical User Interface (GUI) tramite MATLAB App Designer per rendere il tool user-friendly.
Addestramento di modelli di Machine Learning (es. SVM o CNN) sulle matrici del $\Delta SQNR$ calcolate per automatizzare e innalzare la sensibilità di rilevamento.

## Autore
**Massimiliano Cassia** (Matricola: 1000016487)
Università degli Studi di Catania - Corso di Laurea Magistrale in Informatica
Progetto per il corso di Multimedia (Prof. Dario Allegra, Prof. Filippo Stanco) - A.A. 2025/2026
