#!/usr/bin/env python
# -*- coding: utf-8 -*-
# prerequis : librairie pylab installée (regroupe scypy, matplotlib, numpy et ipython)


from pylab import *
import colorsys


from scipy import misc

execfile('kmeansTeinte.py')

img_rgb=misc.imread('miro.jpg')





#passage à TLS
print("calcul des TLS...\n")
img_hls=zeros((len(img_rgb),len(img_rgb[0]),3))
listePointsTeinte=[]
for i in range(len(img_rgb)):
    for j in range(len(img_rgb[0])):
        hls=colorsys.rgb_to_hls(img_rgb[i][j][0]/255.,img_rgb[i][j][1]/255.,img_rgb[i][j][2]/255.)
        listePointsTeinte.append((i,j,hls[0]))
        
        #img_hls[i][j][0]=hls[0]
        
        img_hls[i][j][1]=hls[1]
        img_hls[i][j][2]=hls[2]
        


print("lancement des kmeans...\n")
(listePointsTeinte,centres)=kmeans(listePointsTeinte,4)  




print("\nrajout de la nouvelle valeur de teinte...\n")
for i in range(len(listePointsTeinte)):
    for j in range(len(listePointsTeinte[i])):
        img_hls[(listePointsTeinte[i][j][0])][(listePointsTeinte[i][j][1])][0]=centres[i]
    




print("calcul des RGB...\n")
img_rgb2=zeros((len(img_rgb),len(img_rgb[0]),3))


for i in range(len(img_rgb2)):
    for j in range(len(img_rgb2[0])):
        rgb=colorsys.hls_to_rgb(img_hls[i][j][0],img_hls[i][j][1],img_hls[i][j][2])
        
        
        
        img_rgb2[i][j][0]=rgb[0]*255
        img_rgb2[i][j][1]=rgb[1]*255
        img_rgb2[i][j][2]=rgb[2]*255







print("\nenregistrement de l'image...\n")
misc.imsave('miro_4_teinte_1.jpg', img_rgb2)



print("this is the end")


#[0.62139478500146839, 0.06060628677645348]
#[0.058257891099336843, 0.90297511481120596, 0.55838992574012125]
#[0.23068705596749758, 0.64086015785818262, 0.012727544958567748]
#pour matisse 3_1
#[0.051725344896016386, 0.44960274962037039, 0.70840356198571097]
#pour matisse 3_2

#[0.0087238604227016462, 0.19314894580585926, 0.71314739046114339, 0.48533898192435526]
#matisse 4_1

#[0.051725344896016386, 0.44960274962037039, 0.70840356198571097]
#matisse 4_2

#[0.19054340483931861, 0.0084057043936887101, 0.47022482166551161, 0.92236065458818683, 0.63598332504423749]
#matisse 5_1

#[0.9138381004192313, 0.0022637961376858269, 0.47317179843931528, 0.10227308342998473, 0.21461325647889207, 0.63322389705767579]

#matisse 6_1

#[0.49010796718317201, 0.63440592499918902, 0.91387278456725529, 0.34014464013738638, 0.0022014994129912627, 0.20015743775821659, 0.099698942283911629]

#matisse 7_1





