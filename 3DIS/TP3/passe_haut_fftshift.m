function [I2]=passe_bas_fftshift(p,I)

disp(['on supprime ' num2str(p) '% des coeefs'])


p=p/100;


%p=1-p;


spectrenorm=fftshift(fft2(I));

spectre=log(abs(fftshift(fft2(I))));

figure()
%imagesc(spectre)
colormap(gray(256))

[l,h]=size(spectre);


l1=floor((l*(1-sqrt(p)))/2);
h1=floor((h*(1-sqrt(p)))/2);

spectre(h1:(end-h1),l1:(end-l1))=0.;




imagesc(spectre)
colormap(gray(256))


[l2,h2]=size(spectrenorm);

l3=floor((l2*(1-sqrt(p)))/2);
h3=floor((h2*(1-sqrt(p)))/2);

spectrenorm(h3:(end-h3),l3:(end-l3))=0.;

I2=(ifft2(ifftshift(spectrenorm)));

figure()


imagesc(abs(I2))
colormap(gray(256))





