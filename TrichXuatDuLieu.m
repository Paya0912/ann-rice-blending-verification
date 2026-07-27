clc; clear; close all;
fprintf('=================================\n');
fprintf('TRÍCH XUẤT 9 ĐẶC TRƯNG CHUYÊN SÂU\n');
fprintf('=================================\n');

folders = {'Gao_ST25', 'Gao_DaiThom8', 'Gao_HamChau'};
max_samples = 50000; 
Dynamic_Dataset = zeros(max_samples, 10); % 9 đặc trưng + 1 nhãn = 10 cột
idx = 0; 

for class_id = 1:length(folders)
    current_folder = folders{class_id};
    
    if ~exist(current_folder, 'dir')
        warning('Khong tim thay thu muc "%s", vui long kiem tra lai!', current_folder);
        continue;
    end
    
    file_list = dir(fullfile(current_folder, '*.jpg'));
    fprintf('Đang xử lý folder: %s (%d ảnh)...\n', current_folder, length(file_list));
    
    for f = 1:length(file_list)
        img_path = fullfile(current_folder, file_list(f).name);
        I = imread(img_path);
        Igray = rgb2gray(I);
        
        bw = imbinarize(Igray, 'adaptive', 'Sensitivity', 0.5);
        bw = imfill(bw, 'holes');
        bw = bwareaopen(bw, 40);
        
        % Tách hạt dính bằng Marker-Controlled Watershed
        D = -bwdist(~bw);
        mask = imextendedmin(D, 2);          
        D_imposed = imimposemin(D, mask);    
        L = watershed(D_imposed); 
        bw(L == 0) = 0;   
        
        % Trích xuất đặc trưng hình học + độ sáng màu sắc
        stats = regionprops(bw, Igray, 'Area', 'MajorAxisLength', 'MinorAxisLength', ...
            'Eccentricity', 'Perimeter', 'Solidity', 'MeanIntensity', 'PixelValues');
        
        for k = 1:length(stats)
            Area = stats(k).Area;
            Major = stats(k).MajorAxisLength;
            Minor = stats(k).MinorAxisLength;
            Ecc = stats(k).Eccentricity;
            Perim = stats(k).Perimeter;
            Solid = stats(k).Solidity;
            MeanInt = stats(k).MeanIntensity;
            StdInt = std(double(stats(k).PixelValues)); % Độ đồng đều màu sắc
            AspectRatio = Major / Minor;
            
            if Area > 350 && AspectRatio > 1.2
                idx = idx + 1;
                % Lưu đủ 9 đặc trưng
                Dynamic_Dataset(idx, :) = [Area, Major, Minor, Ecc, AspectRatio, Perim, Solid, MeanInt, StdInt, class_id];
            end
        end
    end
end

Dynamic_Dataset = Dynamic_Dataset(1:idx, :);

Header = {'Area', 'MajorAxisLength', 'MinorAxisLength', 'Eccentricity', 'AspectRatio', ...
          'Perimeter', 'Solidity', 'MeanIntensity', 'StdIntensity', 'Label'};
T = array2table(Dynamic_Dataset, 'VariableNames', Header);
writetable(T, 'DuLieu_Gao.xlsx');

fprintf('HOÀN TẤT! Đã trích xuất 9 đặc trưng cho %d hạt gạo.\n', idx);