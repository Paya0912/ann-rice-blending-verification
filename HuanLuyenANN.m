clc; clear; close all;
fprintf('===================\n');
fprintf('HUẤN LUYỆN MẠNG ANN\n');
fprintf('===================\n');

excel_file = 'DuLieu_Gao.xlsx';
if ~exist(excel_file, 'file')
    error('Không tìm thấy file %s!', excel_file);
end

data = readtable(excel_file);
X = data{:, 1:9}; % Lấy đủ 9 đặc trưng đầu vào
Y = data{:, 10};  % Nhãn Label (1, 2, 3)

inputs = X';            
targets = dummyvar(Y)'; 

% Nâng cấp lên mạng 2 lớp ẩn [20 nơ-ron, 10 nơ-ron]
hiddenLayerSize = [20, 10]; 
net = patternnet(hiddenLayerSize);

net.divideParam.trainRatio = 70/100; 
net.divideParam.valRatio = 15/100;   
net.divideParam.testRatio = 15/100;  
net.trainParam.epochs = 300;
net.trainFcn = 'trainlm'; 

fprintf('Đang huấn luyện mạng ANN đa tầng, vui lòng chờ...\n');
[net, tr] = train(net, inputs, targets);

save('BoNaoGaoANN.mat', 'net');

outputs = net(inputs);
[~, cm, ~, ~] = confusion(targets, outputs);
accuracy = sum(diag(cm)) / sum(cm(:)) * 100;

fprintf('\n==================================================\n');
fprintf('HUẤN LUYỆN HOÀN TẤT!\n');
fprintf('Độ chính xác mới: %.2f%%\n', accuracy);
fprintf('Đã lưu bộ não vào file BoNaoGaoANN.mat\n');
fprintf('==================================================\n');

plotconfusion(targets, outputs);