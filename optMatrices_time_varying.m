function [A, b] = optMatrices_time_varying(params, n_cur, t_cur)
%% This function returns the linear inequality matrices of constraints
% extracting parameters
w = params.w;
f_bar = params.f_bar;
n_bar = params.n_bar;
beta_bar = 1 - params.beta;
ml_d = params.d_up_tv(:,t_cur);
has_or = params.has_or;
%% preallocating matrices
n_seg = size(has_or,1);
or_ind = find(has_or);
n_or = size(or_ind,1);
A = zeros(n_seg*2-1,n_or);
b = zeros(n_seg*2-1,1);
b_d = zeros(n_seg*2-1,1);
%% Constructing matrices
or_count = 0;
iter_row = zeros(2,n_or);
for iter = 1:n_seg-1
    row_ind = 2*(iter-1)+1;
    seg_ind = iter;
    %% A matrix
    % new block
    new_row = iter_row*beta_bar(seg_ind);
    A(row_ind:row_ind+1,:) = new_row;
    if has_or(seg_ind)
        or_count = or_count + 1;
        A(row_ind,or_count) = beta_bar(seg_ind);
        A(row_ind+1,or_count) = beta_bar(seg_ind);
    end
    %% b_d
    b_d(row_ind:row_ind+1,:) = [prod(beta_bar(1:seg_ind,1))*ml_d(1);prod(beta_bar(1:seg_ind,1))*ml_d(1)];
    b(row_ind:row_ind+1,:) = [f_bar(seg_ind);w(seg_ind+1)*(n_bar(seg_ind+1)-n_cur(seg_ind+1))];
    %% update iterative row
    iter_row = A(row_ind:row_ind+1,:);
end
A(end,:) = beta_bar(end)*A(end-2,:);
if has_or(end)
    or_count = or_count + 1;
    A(end,or_count) = beta_bar(end);
end
%% b_d
b_d(end,:) = prod(beta_bar(1:seg_ind,1))*ml_d(1);
b(end) = f_bar(end);
b = b - b_d;



