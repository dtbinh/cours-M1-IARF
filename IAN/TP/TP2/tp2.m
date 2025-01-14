%matlab R2012a option native fonctionne

close 'all'

[sig,fs,nbits,opt]=wavread('P2.5s.wav');

%on passe d'un signal compris compris entre 0 et 1 a un signal entre 2^(nbits-1) et -2^(nbits-1)
sig = (sig.*(2^(nbits-1)) );

%ou si ca marche

[sig,fs,nbits,opt]=wavread('P2.5s.wav','native');


%[y,fs,nbits,opt]=wavread('P2.5s.wav',[2600,3623]);

extrait=sig(2600:3623);


wavwrite((extrait),fs,nbits,'extrait');

extrait=double(extrait);


fig=figure();
%pour avoir la figure en plein écran
set(fig, 'Units', 'Normalized', 'Position', [0 0 1 1]);


%affichage du signal
subplot(5,1,1);

%on met a jour l'echelle du temps
t=(0:length(extrait)-1)/fs;

%on met a jour l'echelle des frequences
f=((0:length(extrait)-1)*fs)/(length(extrait)-1);

plot(t,extrait,'r');

xlabel('Temps(en sec)');

ylabel('Amplitude');

legend('signal');

%affichage de la fenêtre de Hamming
subplot(5,1,2);

fen_ham=hamming(1024);

plot(t,fen_ham,'b');

legend('fenetre Hamming');

xlabel('Temps(en sec)');

ylabel('Amplitude');

%affichage du signal fenêtré par Hamming
subplot(5,1,3);

sig_fen=extrait.*fen_ham;

plot(t,sig_fen,'g');

legend('signal Hamming');

xlabel('Temps(en sec)');

ylabel('Amplitude');

%affichage du spectre du signal

subplot(5,1,4);

fft_standard=abs(fft(extrait));


plot(f,fft_standard,'m');

legend('fft');

xlabel('Frequences(en Hz)');

ylabel('Amplitude');

%affichage du spectre du signal fenêtré 
subplot(5,1,5);

fft_sig_ham=abs(fft(sig_fen));


plot(f,fft_sig_ham,'k');

legend('fft Hamming');

xlabel('Frequences(en Hz)');

ylabel('Amplitude');


%calculer l'energie toutes les 10 ms

%affichage des fenetrages de Hamming, Hanning, Blackman et Rectwin

fig2=figure();


hold on;
%subplot(4,1,1);

plot(fen_ham,'r');
legend('Hamming');

%subplot(4,1,2);

fen_han=hanning(1024);

plot(fen_han,'b');
legend('Hanning');
%subplot(4,1,3);

fen_black=blackman(1024);

plot(fen_black,'m');
legend('Blackman');
%subplot(4,1,4);

fen_rect=rectwin(1024);

plot(fen_rect,'k');
legend('Hamming','Hanning','BlackMan','RectWin');

%pour avoir la figure en plein écran
set(fig2, 'Units', 'Normalized', 'Position', [0 0 1 1]);




%on affiche les différentes réponses spectrales de chaque fenêtre
fig3=figure();

hold on;

sig_fen_ham=extrait.*fen_ham;

sig_fen_han=extrait.*fen_han;

sig_fen_black=extrait.*fen_black;

sig_fen_rect=extrait.*fen_rect;

fft_sig_ham=abs(fft(sig_fen_ham));

fft_sig_han=abs(fft(sig_fen_han));

fft_sig_black=abs(fft(sig_fen_black));

fft_sig_rect=abs(fft(sig_fen_rect));

subplot(4,1,1);

plot(f,fft_sig_ham,'r');
legend('Hamming');
xlabel('Frequences(en Hz)');
ylabel('Amplitude');


subplot(4,1,2);

plot(f,fft_sig_han,'b');
legend('Hanning');
xlabel('Frequences(en Hz)');
ylabel('Amplitude');

subplot(4,1,3);

plot(f,fft_sig_black,'m');
legend('BlackMan');
xlabel('Frequences(en Hz)');
ylabel('Amplitude');

subplot(4,1,4);

plot(f,fft_sig_rect,'k');
legend('RectWin');
xlabel('Frequences(en Hz)');
ylabel('Amplitude');



%pour avoir la figure en plein écran
set(fig3, 'Units', 'Normalized', 'Position', [0 0 1 1]);


%on calcule l'energie du signal

fig4=figure();
res=energie(sig,160,80);



%plot(10*log10(res));


t=((0:(length(res)-1))*((length(sig)-1)/fs))/(length(res)-1);
plot(t,10*log10(res));

legend('energie');

xlabel('Temps(en sec)');

ylabel('Energie(en dB)');

%pour avoir la figure en plein écran
set(fig4, 'Units', 'Normalized', 'Position', [0 0 1 1]);

%on calcule et affiche l'autocorrelation
[lags,C]=auto_corr_win(extrait,fs);




%on garde que la partie positive et la partie comprise entre 50 et 500Hz
lags=lags( floor((end/2)+(fs/500)) :floor((end/2)+(fs/50)) );
C=C(floor((end/2)+(fs/500)) :floor((end/2)+(fs/50)) );

figure()
%on reaffiche la fenetre concernée
plot(lags,C);

%on prend l'indice position du max C
[maximum position] = max(C);
%et on renvoie le lag associé
T0=lags(position);

F0=1/T0;

freqs=freq_fond(double(sig), 1024, 160,fs);

figure();

t=(0:length(freqs)-1)*(length(sig)-1)/(fs*length(freqs)-1);

plot(t,freqs)

xlabel('Temps(en sec)');

ylabel('frequences(en Hz)');

legend('frequences fondamentales');








