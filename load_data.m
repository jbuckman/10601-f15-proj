%% load_data: load everything
function [td, tl, vd, vl] = load_data()
    addpath '/home/john/Documents/10601-f15-proj/vlfeat-0.9.20';
    cd vlfeat-0.9.20/toolbox;
    vl_setup;
    cd ../../subset_CIFAR10;
    [td, tl] = combine(1:5);
    cd ../cifar-10-batches-mat
    load('data_batch_1.mat');
    idx = randperm(size(data,1),1000);
    vd = data(idx,:);
    vl = labels(idx,:);
    cd ..;
end
