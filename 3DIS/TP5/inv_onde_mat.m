function [I2]=inv_onde_mat(I,h,g)

[s1,s2] = size(I);

I2=zeros(s1,s2);

hs1=floor(s1/2);
hs2=floor(s2/2);
mat=zeros(2,2);


for i=1:hs1
  for j=1:hs2
    mat(1,1)=I(i,j);
    mat(1,2)=I(i,hs2+j);
    mat(2,1)=I(i+hs1,j);
    mat(2,2)=I(i+hs1,hs2+j);

    I_calc=onde2x2(mat,h,g);
    
    I2(2*(i-1)+1,2*(j-1)+1)=I_calc(1,1);
    I2(2*(i-1)+1,2*(j-1)+2)=I_calc(1,2);
    I2(2*(i-1)+2,2*(j-1)+1)=I_calc(2,1);
    I2(2*(i-1)+2,2*(j-1)+2)=I_calc(2,2);


    %I2((i+1)/2,((j+1)/2)) = I_calc(1,1);
    %I2(floor(end/2)+((i+1)/2),((j+1)/2)) = I_calc(1,2);
    %I2(((i+1)/2),floor(end/2)+((j+1)/2)) = I_calc(2,1);
    %I2(floor(end/2)+((i+1)/2),floor(end/2)+((j+1)/2)) = I_calc(2,2);
  end
end
    
    
