function  [chemin dynamicT coutTotal,ens_chem] = DTW_IAN(test,ref)

%chemin : matrice contenant le chemin optimal (2=cellule du chemin optimal, 1=non optimal)

%dynamicT: matrice dim2 des couts

%coutTotal : cout du chemin optimal




%ensemble, chaque cellule de l'ensemble ens_chem(i,j) contiendra:
% 1 si chemin de (i,j-1) à (i,j) = horizontal
% 2 si chemin de (i-1,j-1) à (i,j) = diagonal
% 3 si chemin de (i-1,j) à (i,j) = vertical




[s1,s2] = size(test); %s1 taille des vecteurs cepstraux ,s2 nb de vecteurs cepstraux
[s3,s4] = size(ref); %s3 taille des vecteurs cepstraux ,s4 nb de vecteurs cepstraux

%on a donc s4 nb lignes et s2 nb volones

%on initialise la matrice des couts

dynamicT=zeros(s4+1,s2+1);

%on initialise la matrice des chemins
chemin=ones(s4+1,s2+1);

dynamicT(1,2:end)=inf;
dynamicT(2:end,1)=inf;

%On creer un ensemble de cellules qui contiendra, pour chaque celle, le(s) chemin(s) (cellule) à partir desqels on peut acceder
% chaque cellule contien donc une liste, cette liste contient:
% liste vide si on ne peut pas y accéder (seulement sur la première ligne et la première colone
% 1 si on peut y accéder par la case à gauche
% 2 si on peut y accéder par la case diagonale haut gauche
% 3 si on peut y accéder par la case d'en haut 


ens_chem=cell(s4+1,s2+1);

for i=2:s4+1

   for j=2:s2+1
        
        distance= sqrt( sum( ( test(:,j-1) - ref(:,i-1) ).^2 ));   
        c1=dynamicT(i,j-1) + distance;
        c2=dynamicT(i-1,j-1) + 2*distance;
        c3=dynamicT(i-1,j) + distance;
        dynamicT(i,j) = min([c1,c2,c3]);

        if min([c1,c2,c3]) == c1
            ens_chem{i,j}=[ens_chem{i,j},1];

        end

        if min([c1,c2,c3]) == c2
            ens_chem{i,j}=[ens_chem{i,j},2];

        end

         if min([c1,c2,c3]) == c3
            ens_chem{i,j}=[ens_chem{i,j},3];

        end
        m=min([c1,c2,c3]);
        if (c1 == m) && (c2 == m)
            ['bifurcation dans le chemin: c1= ' num2str(c1) ' c2= ' num2str(c2)]
        end
        if (c1 == m) && (c3 == m)
            ['bifurcation dans le chemin: c1= ' num2str(c1) ' c3= ' num2str(c3)]
        end
        if (c2 == m) && (c3 == m)
            ['bifurcation dans le chemin: c1= ' num2str(c2) ' c3= ' num2str(c3)]
        end









    end
end

coutTotal=dynamicT(s4+1,s2+1);
coutTotal=coutTotal/(s2+s4);

a=s4+1;
b=s2+1;

chemin(a,b)=2;

%tant qu'on a pas atteint la cellule 2,2 de ens_chem
while (a~=2) || (b~=2)
    %si 2 appartient à la liste qui se trouve dans la cellule a,b (cas diagonal)
    if max(ens_chem{a,b}==2)>0
        %on met la valeur de chemin(a-1,b-1) à 2 et on maj la valeur de a et b   
        a=a-1;
        b=b-1;
        chemin(a,b)=2;
    
 
    %on met une priorité arbitraire sur la rège horizontal, on verra dans le rapport que l'ordre n'a pas d'importance dans le cas present
    %si 1 appartient à la liste qui se trouve dans la cellule a,b (cas horizontal)
    elseif max(ens_chem{a,b}==1)>0
        %on met la valeur de chemin(a,b-1) à 2 et on maj la valeur de a et b   
        b=b-1;
        chemin(a,b)=2;
    

    %si 3 appartient à la liste qui se trouve dans la cellule a,b (cas horizontal)
    elseif max(ens_chem{a,b}==3)>0
        %on met la valeur de chemin(a-1,b) à 2 et on maj la valeur de a et b   
        a=a-1;
        chemin(a,b)=2;
    

    else
        error('on ne peut pas acceder à la case, erreur ');
    end



end

% je remets la matrice des chemins à la bonne taille
chemin(1,:)=[];
chemin(:,1)=[];






