%    The following is an implementation of the guided filter (GF) based
%    context enhancement (GFCE) through fusion of infrared and visible
%    images.
%    Ref: Zhiqiang Zhou et al. "Fusion of infrared and visible images for night-vision context 
%    enhancement", Applied Optics, 55(23), 2016
%    
%    Some of the test images were obtained at
%      http://www.imagefusion.org
%      http://www.ece.lehigh.edu/SPCRL/IF/image_fusion.htm
%
%    Zhiqiang Zhou, Beijing Institute of Technology
%    Apr. 2016
for iname =1:42

% close all;
nLevel = 4;
name = num2str(iname);
%  path_Vis = '.\image\b01_1.tif';      path_IR = '.\image\b01_2.tif';
path_Vis = ['C:\Users\Administrator\Desktop\20230225VIF\VIFB1\input\roadscene\vi_bmp_hui\',name,'.bmp']; path_IR = ['C:\Users\Administrator\Desktop\20230225VIF\VIFB1\input\roadscene\ir_bmp_hui\',name,'.bmp'];
% path_Vis = '.\image\Trees4906_Vis.jpg'; path_IR = '.\image\Trees4906_IR.jpg';
% path_Vis = '.\image\Octec_Vis.jpg';     path_IR = '.\image\Octec_IR.jpg';
% path_Vis = '.\image\Road_Vis.jpg';      path_IR = '.\image\Road_IR.jpg';
% path_Vis = '.\image\Kayak_Vis.jpg';     path_IR = '.\image\Kayak_IR.jpg';
% path_Vis = '.\image\Steamboat_Vis.jpg'; path_IR = '.\image\Steamboat_IR.jpg';
% path_Vis = '.\image\Trees4917_Vis.jpg'; path_IR = '.\image\Trees4917_IR.jpg';
% path_Vis = '.\image\Dune_Vis.jpg';      path_IR = '.\image\Dune_IR.jpg';

[img1, img2, para.name] = PickName(path_Vis, path_IR);
paraShow1.fig = 'Visible image';
paraShow2.fig = 'Infrared image';


%% ---------- Visibility enhancement for visible image--------------
img1E = Ehn_GF(img1);
img1 = img1E;


%% ---------- Infrared image normalization--------------
mi = min(img2(:));
ma = max(img2(:));
img2 = (img2-mi)/(ma-mi)*255;
%img2 = rgb2gray(img2);
%% ---------- Automatic parameter selection --------------
Rs = Relative_PS(img2, img1);
if Rs<0.8
    lambda = 100
else
    if Rs>1.6
        lambda = 2000
    else
        lambda = 2500*Rs - 1900
    end
end    

%% ---------- Hybrid multiscale decomposition based on guided filter--------------
sigma = 2;  k = 2;
r0 = 2;     eps0 = 0.1;  
l = 2;

M1 = cell(1, nLevel+1);
M1L = cell(1, nLevel+1);
M1{1} = img1/255;
M1L{1} = M1{1};
M1D = cell(1, nLevel+1);
M1E = cell(1, nLevel+1);
sigma0 = sigma;
r = r0;
eps = eps0;
for ii = 2:nLevel+1,
    
%     % ***using fast guided filter, which has the potential to achieve real-time performance when codes are fully optimized
%     % ***NOTE: large subsampling ratio may cause problem for fusion of some source images.
%     s = max(1, r/2); % subsampling ratio
%     M1{ii} = fastguidedfilter_md(M1{ii-1}, M1{ii-1}, r, 100^2, s);  
%     M1L{ii} = fastguidedfilter_md(M1L{ii-1}, M1L{ii-1}, r, eps^2, s);
    
    M1{ii} = guidedfilter(M1{ii-1}, M1{ii-1}, r, 100^2);  
    M1L{ii} = guidedfilter(M1L{ii-1}, M1L{ii-1}, r, eps^2);    
    
    M1D{ii} = M1{ii-1} - M1L{ii};
    M1E{ii} = M1L{ii} - M1{ii};
    
    sigma0 = k*sigma0;
    r = k*r;
    eps = eps/l;
end

M2 = cell(1, nLevel+1);
M2L = cell(1, nLevel+1);
M2{1} = img2/255;
M2L{1} = M2{1};
M2D = cell(1, nLevel+1);
M2E = cell(1, nLevel+1);
sigma0 = sigma;
r = r0;
eps = eps0;
for ii = 2:nLevel+1,
%     s = max(1, r/2);
%     M2{ii} = fastguidedfilter_md(M2{ii-1}, M2{ii-1}, r, 100^2, s);
%     M2L{ii} = fastguidedfilter_md(M2L{ii-1}, M2L{ii-1}, r, eps^2, s);
    M2{ii} = guidedfilter(M2{ii-1}, M2{ii-1}, r, 100^2);
    M2L{ii} = guidedfilter(M2L{ii-1}, M2L{ii-1}, r, eps^2);    
 
    M2D{ii} = M2{ii-1} - M2L{ii};
    M2E{ii} = M2L{ii} - M2{ii};

    sigma0 = k*sigma0;
    r = k*r;
    eps = eps/l;
end

%% ---------- Fusion --------------

for j = nLevel+1:-1:3
D2 = abs(M2E{j});
D1 = abs(M1E{j});
R = max(D2-D1, 0);
Rmax = max(R(:));
P = R/Rmax;

Cj = atan(lambda*P)/atan(lambda);

sigma_b = 2*sigma0;
if j == nLevel+1
    w = floor(3*sigma_b);
    h = fspecial('gaussian', [2*w+1, 2*w+1], sigma_b);
    lambda0 = lambda;
    Cb = atan(lambda0*P)/atan(lambda0);
    Cb = imfilter(Cb, h, 'symmetric');
    MB = Cb.*M2{nLevel+1} + (1-Cb).*M1{nLevel+1};
end

sigma_c = 1;
w = floor(3*sigma_c);
h = fspecial('gaussian', [2*w+1, 2*w+1], sigma_c);   
Cj = imfilter(Cj, h, 'symmetric');

md = Cj.*M2E{j}+ (1-Cj).*M1E{j};
MB = MB + md;
md = Cj.*M2D{j}+ (1-Cj).*M1D{j};
MB = MB + md;
end 

sigma_t = 1;
w = floor(3*sigma_t);
h = fspecial('gaussian', [2*w+1, 2*w+1], sigma_t);   
C11 = double(abs(M1E{2}) < abs(M2E{2}));
C11 = imfilter(C11, h, 'symmetric');
md = C11.*M2E{2}+ (1-C11).*M1E{2};
MB = MB + md;  
C10 = double(abs(M1D{2}) < abs(M2D{2}));
md = C10.*M2D{2}+ (1-C10).*M1D{2};
MB = MB + md;
FI = min(round(MB*275), 255);
FI = max(FI, 0);

paraShow.fig = 'Result';
ShowImageGrad(FI, paraShow,iname);

end
