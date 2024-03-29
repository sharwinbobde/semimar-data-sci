data = readtable('./data/iris.data.csv');
X = data( :, 1:(size(data,2)-1));
labels = data(:, size(data,2));

X = table2array(X);
labels = table2array(labels);

%%
disp(unique(labels))
disp(size(X))

class(labels)

%%
% Full blown PCA

Y = center_points(X);

G = compute_gram_matrix(Y);

d=2; % reduced to 2 dimentions
mapping = compute_mapping(G, Y, d);

X_low_dim = X * mapping;

plot_2d_scatter(X_low_dim, labels, "PCA with all samples");


% #######################################################################################################
%%

% Test bench (Consistent prior sampling)
sample_rate = 0.03;
[snapshot, snap_labs] = get_constant_prior_snapshot(X, labels, sample_rate); % sample only 20% of datafrom each class
snap_Y = center_points(snapshot);
snap_G = compute_gram_matrix(snap_Y);
snap_mapping = compute_mapping(snap_G, snap_Y, 2);

plot_2d_scatter(snap_Y * snap_mapping, snap_labs, join(['Snapshot S-PCA with ', string(sample_rate*100), '% sampling per class'], ""));
plot_2d_scatter(Y * snap_mapping, labels, join(['Snapshot S-PCA with ', string(sample_rate*100), '% sampling per class'], ""));

%%

% Test bench (Random sampling)
sample_rate = 0.07;
[snapshot, snap_labs] = get_random_snapshot(X, labels, sample_rate); % sample only 20% of datafrom each class
snap_Y = center_points(snapshot);
snap_G = compute_gram_matrix(snap_Y);
snap_mapping = compute_mapping(snap_G, snap_Y, 2);

plot_2d_scatter(snap_Y * snap_mapping, snap_labs, join(['Snapshot S-PCA with ', string(sample_rate*100), '% Random sampling'], ""));
plot_2d_scatter(Y * snap_mapping, labels, join(['Full Data S-PCA with ', string(sample_rate*100), '% Ransom sampling'], ""));


% #######################################################################################################
%% 

function [snapshot, snap_labs] = get_constant_prior_snapshot(x, lab, sampling_ratio)
    classes = unique(lab);
    num_classes = size(classes, 1);
    
    snapshot = [];
    snap_labs = [];
    
    s = RandStream('mlfg6331_64'); 
    
    for i = 1:num_classes
        indexes = find(strcmp(lab, classes(i)));
        k = int16(sampling_ratio * size(indexes,1));
        disp(k);
        select_indexes = datasample(s, indexes, k);
        
        snapshot = vertcat(snapshot, x(select_indexes, :));
        snap_labs = horzcat(snap_labs, (repelem(classes(i), size(select_indexes, 1))));
    end
    snap_labs = snap_labs';
end


%% 

function [snapshot, snap_labs] = get_random_snapshot(x, lab, sampling_ratio)
    s = RandStream('mlfg6331_64'); 
    k = int16(sampling_ratio * size(x,1));
    disp(k);
    select_indexes = datasample(s, 1:size(lab,1), k);
    snapshot = x(select_indexes, :);
    snap_labs = lab(select_indexes, :);
end


%%

function plot_2d_scatter(x, labels, t)
    classes = unique(labels);
    num_classes = size(classes, 1);
    
    colmap = ["r", "g", "b", "y", "m"];
    
    figure();
    for i = 1:num_classes
        indexes = find(strcmp(labels, classes(i)));
    
        scatter(x(indexes,1), x(indexes,2), colmap(i));
        hold on
        c = mean(x(indexes,:));
        text(c(1), c(2), classes(i))
        hold on
    end
    title(t);
end





%%
function [x_c] = center_points(x)
    x_c = x - mean(x);
end

%%
function [G] = compute_gram_matrix(X)
    G = X * X';
end

%%
function [mapping] = compute_mapping(G, Y, d)
    % G: Gram matrix
    % Y: Centred data
    % d: dimentions to map to
    
    [eigenVec,eigenVal] = eigs(G./size(G,2));
    
    [temp, indexes] = sort(diag(eigenVal), 'descend'); % sort eigenvalue
    eigenVal = eigenVal(:, indexes); % sort eigenvals
    eigenVec = eigenVec(:, indexes); % sort eigenvector
    
    eigenValD = diag(sqrt(inv(eigenVal)));
    
    mapping = zeros(size(Y,2), d);
    for i = 1:d
        basis = eigenValD(i).* (Y' * eigenVec(:,i));
        mapping(:,i) = basis;
    end
end