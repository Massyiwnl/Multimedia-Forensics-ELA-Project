%% ANALISI FORENSE ELA (Error Level Analysis) - PROGETTO MULTIMEDIA
% Studente: Massimiliano CASSIA
% Obiettivo: Rilevamento automatico di manipolazioni tramite analisi residuo di quantizzazione
% Tecniche: YCbCr Colorspace, Adaptive Quality Sweep, DCT Frequency Analysis

clear; close all; clc;

%% 1. CONFIGURAZIONE E CARICAMENTO
input_file = 'dataset/evidence_fake.jpg';
temp_file = 'output/temp_resaved.jpg';

if ~isfile(input_file)
    error('ERRORE: File "evidence_fake.jpg" non trovato nella cartella dataset.');
end

orig_img = imread(input_file);
fprintf('--- AVVIO ANALISI FORENSE SU: %s ---\n', input_file);

%% 2. PRE-PROCESSING (Spazio Colore YCbCr)
% Teoria Video Digitale: Il JPEG comprime Luminanza (Y) e Crominanza (CbCr) separatamente.
% Lavorare sulla Luminanza (Y) rivela meglio le incongruenze strutturali.
orig_ycbcr = rgb2ycbcr(orig_img);
orig_Y = double(orig_ycbcr(:,:,1)); 
[h, w] = size(orig_Y);

%% 3. CREAZIONE DEL RESIDUO ELA (Metodo Standard)
% Invece dello sweep, forziamo una compressione fissa (es. 90%)
% per far emergere i delta di quantizzazione.
ela_quality = 90;
fprintf('Generazione artefatti ELA al %d%%... ', ela_quality);
imwrite(orig_img, temp_file, 'jpg', 'Quality', ela_quality);

resaved_temp = imread(temp_file);
resaved_Y = double(rgb2ycbcr(resaved_temp));
resaved_Y = resaved_Y(:,:,1);

% Residuo
best_diff_map = abs(orig_Y - resaved_Y);

% Calcolo SQNR Globale in dB
power_signal = mean(orig_Y(:).^2);
power_noise = mean(best_diff_map(:).^2);
sqnr_global_db = 10 * log10(power_signal / power_noise);
fprintf('COMPLETATO. SQNR Stimato: %.2f dB\n', sqnr_global_db);

%% 4. ELABORAZIONE FORENSE E FILTRAGGIO
% Amplificazione dell'errore per visualizzazione (Brightness Scaling)
scale_factor = 40; 
ela_raw = best_diff_map * scale_factor;

% Filtro Mediano (Rimuove rumore impulsivo "sale e pepe")
ela_filtered = medfilt2(ela_raw, [3 3]);

% Filtro Gaussiano (Crea la Heatmap di densità errore)
heatmap_final = imgaussfilt(ela_filtered, 2);

%% 5. RILEVAMENTO AUTOMATICO E CALCOLO SQNR LOCALE
[maxVal, maxIdx] = max(heatmap_final(:));
[y_fake, x_fake] = ind2sub(size(heatmap_final), maxIdx);

% ALLINEAMENTO ALLA GRIGLIA 8x8 DEL JPEG 
% Troviamo l'inizio del vero blocco JPEG 8x8 a cui appartiene il pixel anomalo
block_start_y = floor((y_fake - 1) / 8) * 8 + 1;
block_start_x = floor((x_fake - 1) / 8) * 8 + 1;

% Protezione bordi aggiornata
if block_start_x < 1 || block_start_x > w-7 || block_start_y < 1 || block_start_y > h-7
    block_start_x = 1; block_start_y = 1; 
end

%% 5.1 CALCOLO SQNR LOCALE DIFFERENZIALE (Delta SQNR)
% Calcolo potenza del segnale e del rumore SOLO per il blocco sospetto
block_fake_signal = orig_Y(block_start_y : block_start_y+7, block_start_x : block_start_x+7);
block_fake_noise = best_diff_map(block_start_y : block_start_y+7, block_start_x : block_start_x+7);

pow_sig_fake = mean(block_fake_signal(:).^2);
pow_noise_fake = mean(block_fake_noise(:).^2);
if pow_noise_fake == 0; pow_noise_fake = 1e-10; end % Protezione div/0
sqnr_local_fake_db = 10 * log10(pow_sig_fake / pow_noise_fake);

% Calcolo su un blocco di controllo (sfondo simulato - es. alto a sinistra)
bg_y = 1; bg_x = 1;
block_bg_signal = orig_Y(bg_y : bg_y+7, bg_x : bg_x+7);
block_bg_noise = best_diff_map(bg_y : bg_y+7, bg_x : bg_x+7);

pow_sig_bg = mean(block_bg_signal(:).^2);
pow_noise_bg = mean(block_bg_noise(:).^2);
if pow_noise_bg == 0; pow_noise_bg = 1e-10; end
sqnr_local_bg_db = 10 * log10(pow_sig_bg / pow_noise_bg);

delta_sqnr = abs(sqnr_local_bg_db - sqnr_local_fake_db);
fprintf('\n--- ANALISI DIFFERENZIALE ---\n');
fprintf('SQNR Locale (Sfondo Sicuro): %.2f dB\n', sqnr_local_bg_db);
fprintf('SQNR Locale (Area Anomala):  %.2f dB\n', sqnr_local_fake_db);
fprintf('DELTA SQNR RILEVATO:         %.2f dB\n\n', delta_sqnr);

%% 6. ANALISI SPETTRALE (DCT Rigorosa)
% Estraiamo il VERO blocco 8x8 della griglia JPEG
block_fake = orig_Y(block_start_y : block_start_y+7, block_start_x : block_start_x+7);

% Trasformata DCT 2D e calcolo magnitudo
dct_fake = abs(dct2(block_fake));
% Applichiamo logaritmo per una migliore visualizzazione (+1 per evitare log(0))
dct_fake_log = log(dct_fake + 1);

%% 7. VISUALIZZAZIONE DASHBOARD (Output Finale)
figure('Name', 'Analisi Forense Avanzata - Progetto Multimedia', 'Color', 'w', 'Position', [100, 100, 1200, 600]);

% A. Immagine Originale
subplot(2, 3, 1);
imshow(orig_img);
title('1. Evidenza (Input)', 'FontWeight', 'bold');

% B. Canale Luminanza
subplot(2, 3, 2);
imshow(uint8(orig_Y));
title('2. Canale Luminanza (Analisi Y)', 'FontWeight', 'bold');

% C. ELA Grezzo
subplot(2, 3, 3);
imshow(uint8(ela_raw));
title(['3. ELA Raw (Scala x', num2str(scale_factor), ')'], 'FontWeight', 'bold');

% D. Heatmap Scientifica (Il risultato principale)
subplot(2, 3, [4 5]);
imagesc(heatmap_final);
colormap(jet); colorbar; axis image; axis off;
title(['4. Heatmap Energetica (Sospetto in ROSSO) - Q: ' num2str(ela_quality) '%'], 'FontSize', 12, 'FontWeight', 'bold');

% Disegno Box sull'anomalia rilevata
hold on;
rectangle('Position', [x_fake-25, y_fake-25, 50, 50], 'EdgeColor', 'w', 'LineWidth', 2, 'LineStyle', '--');
text(x_fake, y_fake-35, 'FAKE DETECTED', 'Color', 'w', 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'BackgroundColor', 'k');

% E. Firma Spettrale DCT
subplot(2, 3, 6);
bar3(dct_fake(1:4,1:4)); % Mostriamo solo le basse frequenze
title('5. Firma DCT (Blocco Sospetto)', 'FontWeight', 'bold');
zlabel('Magnitudo Frequenze');
view(-30, 30);

sgtitle(['REPORT FORENSE AUTOMATICO - SQNR Globale: ' num2str(sqnr_global_db, '%.2f') ' dB'], 'FontSize', 16, 'Color', 'r', 'FontWeight', 'bold');

% Pulizia finale
if exist(temp_file, 'file')
    delete(temp_file);
end