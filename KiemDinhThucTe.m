clc; clear; close all;
fprintf('============================================\n');
fprintf('HỆ THỐNG AI KIỂM ĐỊNH TỶ LỆ TRỘN GẠO THỰC TẾ\n');
fprintf('============================================\n');

brain_file = 'BoNaoGaoANN.mat';
if exist(brain_file, 'file')    
    load(brain_file);
    fprintf('Đã nạp thành công bộ não AI từ file BoNaoGaoANN.mat!\n');
else
    error('Không tìm thấy file BoNaoGaoANN.mat!');
end

[file, path] = uigetfile({'*.jpg;*.png;*.jpeg', 'Chọn ảnh cần kiểm định'});
if isequal(file, 0)
    disp('Đã hủy chọn ảnh kiểm định.');
    return;
end

image_path = fullfile(path, file);
I = imread(image_path);

if size(I, 3) == 3
    Igray = rgb2gray(I);
else
    Igray = I;
end

bw = imbinarize(Igray, 'adaptive', 'Sensitivity', 0.45);
se = strel('disk', 3);
bw = imopen(bw, se); 
bw = imfill(bw, 'holes');
bw = bwareaopen(bw, 150); 

D = -bwdist(~bw);
mask = imextendedmin(D, 2);
D_imposed = imimposemin(D, mask);
L = watershed(D_imposed); 
bw(L == 0) = 0;   

stats = regionprops(bw, Igray, 'Area', 'MajorAxisLength', 'MinorAxisLength', ...
    'Eccentricity', 'Perimeter', 'Solidity', 'MeanIntensity', 'PixelValues', 'Centroid');

num_stats = length(stats);
X_thucte = zeros(num_stats, 9);
centroids = zeros(num_stats, 2);
count = 0;

for k = 1:num_stats
    Area = stats(k).Area;
    Major = stats(k).MajorAxisLength;
    Minor = stats(k).MinorAxisLength;
    Ecc = stats(k).Eccentricity;
    Perim = stats(k).Perimeter;
    Solid = stats(k).Solidity;
    MeanInt = stats(k).MeanIntensity;
    StdInt = std(double(stats(k).PixelValues));
    AspectRatio = Major / Minor;
    
    if Area > 350 && AspectRatio > 1.2
        count = count + 1;
        X_thucte(count, :) = [Area, Major, Minor, Ecc, AspectRatio, Perim, Solid, MeanInt, StdInt];
        centroids(count, :) = stats(k).Centroid; 
    end
end

% Cắt bỏ phần bộ nhớ dư chưa dùng
X_thucte = X_thucte(1:count, :);
centroids = centroids(1:count, :);

if isempty(X_thucte)
    error('Không trích xuất được hạt gạo nào từ ảnh!');
end

inputs_thucte = X_thucte'; 
Y_pred_raw = net(inputs_thucte);
Y_pred = vec2ind(Y_pred_raw); 

tong_so_hat = length(Y_pred);
so_hat_st25 = sum(Y_pred == 1);
so_hat_dt8 = sum(Y_pred == 2);
so_hat_hamchau = sum(Y_pred == 3);

ty_le_st25 = (so_hat_st25 / tong_so_hat) * 100;
ty_le_dt8 = (so_hat_dt8 / tong_so_hat) * 100;
ty_le_hamchau = (so_hat_hamchau / tong_so_hat) * 100;

fprintf('\nKẾT QUẢ PHÂN TÍCH TỰ ĐỘNG TỪ ẢNH "%s":\n', file);
fprintf(' - Tổng số hạt quét được : %d hạt.\n', tong_so_hat);
fprintf(' - Gạo ST25         : %3d hạt (Chiếm: %5.1f%%)\n', so_hat_st25, ty_le_st25);
fprintf(' - Gạo Đài Thơm 8    : %3d hạt (Chiếm: %5.1f%%)\n', so_hat_dt8, ty_le_dt8);
fprintf(' - Gạo Hàm Châu      : %3d hạt (Chiếm: %5.1f%%)\n', so_hat_hamchau, ty_le_hamchau);

% Hien thi anh va tao chu thich mau (Legend)
figure('Name', 'Ket Qua Kiem Dinh Gao', 'NumberTitle', 'off');
imshow(I); hold on;
title(sprintf('ST25: %.1f%% | Dai Thom 8: %.1f%% | Ham Chau: %.1f%%', ty_le_st25, ty_le_dt8, ty_le_hamchau));

% Tạo đối tượng mẫu cho Legend
h_st25 = plot(NaN, NaN, 'go', 'MarkerSize', 8, 'LineWidth', 2, 'DisplayName', 'Gao ST25');
h_dt8 = plot(NaN, NaN, 'bo', 'MarkerSize', 8, 'LineWidth', 2, 'DisplayName', 'Gao Dai Thom 8');
h_hamchau = plot(NaN, NaN, 'ro', 'MarkerSize', 8, 'LineWidth', 2, 'DisplayName', 'Gao Ham Chau');

% Hien thi chu thich phia duoi anh
legend([h_st25, h_dt8, h_hamchau], 'Location', 'southoutside', 'Orientation', 'horizontal');

% Khoanh vùng tung hat gao tren anh
for i = 1:tong_so_hat
    if Y_pred(i) == 1
        plot(centroids(i,1), centroids(i,2), 'go', 'MarkerSize', 8, 'LineWidth', 2, 'HandleVisibility', 'off');
    elseif Y_pred(i) == 2
        plot(centroids(i,1), centroids(i,2), 'bo', 'MarkerSize', 8, 'LineWidth', 2, 'HandleVisibility', 'off');
    else
        plot(centroids(i,1), centroids(i,2), 'ro', 'MarkerSize', 8, 'LineWidth', 2, 'HandleVisibility', 'off');
    end
end
hold off;