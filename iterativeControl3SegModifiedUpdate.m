% x is the primary variable of optimization problem
% alpha's are the prices
% n : mainline density
% l : onramp density
% f : mainline flows
% r : onramp flows 
clear all;
close all;
clc;
% network data
threeSegNetworkStruc;
%% initial condition

n0 = [10;24;24];
l0 = [3;3];
%% setting up the optimization

n_seg = size(params.v,1);
n_or = size(find(params.has_or),1);
or_ind = find(params.has_or);
n_cur = n0;
l_cur = l0;
max_iter = 2000;
% preallocation
x = zeros(n_or,max_iter+1);
alpha = zeros(2*n_seg-1,max_iter+1);
x0 = ones(n_or,1);
alpha0 = ones(2*n_seg-1,1);
alpha(:,1) = alpha0;
x(:,1) = x0;

n = zeros(n_seg,max_iter+1);
l = zeros(n_or, max_iter+1);
f = zeros(n_seg, max_iter);
r = zeros(n_or, max_iter);
n(:,1) = n0;
l(:,1) = l0;
%%
or_it = 0;
f_ss = zeros(n_seg,1);
if params.has_or(1)
    or_it = or_it + 1;
    f_ss(1,1) = (1-params.beta(1))*(params.d_up(1)+params.d(or_it));
else
    f_ss(1,1) = (1-params.beta(1))*(params.d_up(1));
end

for j = 2:n_seg
    if params.has_or(j)
        or_it = or_it + 1;
        f_ss(j) = (1-params.beta(j))*(f_ss(j-1)+params.d(or_it));
    else
        f_ss(j) = (1-params.beta(j))*(f_ss(j-1));
    end
    if f_ss(j) > params.f_bar(j)
        warning('infeasible arrival')
    end
end
%% iterative control

for iter = 1:max_iter
    [A, b] = optMatrices(params, n_cur);
    x_cur = x(:,iter);
%     x_cur = r_cur + 0.01*ones(n_or,1);
    alpha_cur = alpha(:,iter);
    % decreasing sequence
    beta = 1/iter;
    % update primary variables
    fun = @(x) -sum(log(x)) + alpha_cur'*(A*x-b); 
    x_next = fmincon(fun,x0,[],[]);
    % update prices
    alpha_next = alpha_cur + beta * (A*x_cur - b);
    alpha(:,iter+1) = alpha_next;
    x_next = min(x_next, l_cur + params.d);
    r_cur = min(x_next, params.r_bar);
    r_cur = max(r_cur,zeros(n_or,1));
    % storage
    x(:,iter+1) = min(r_cur, l_cur + params.d);
    % control input
%     r_cur = min(x_next, params.r_bar);
%     r_cur = max(r_cur,zeros(n_or,1));
    r_cur = min(r_cur,(params.n_bar(or_ind) - n_cur(or_ind)));
    r_cur = max(r_cur,zeros(n_or,1));
     % storage
    x(:,iter+1) = x_next;
    % evolve model
    [n_next, l_next, f_cur] = fwyDynamics(n_cur, l_cur, r_cur, params);
%     [n_next, l_next, f_cur] = fwyDynamicsStoch(n_cur, l_cur, r_cur, params); 
    % storage
    n(:,iter+1) = n_next;
    l(:,iter+1) = l_next;
    f(:,iter) = f_cur;
    r(:,iter) = r_cur;
    % updating current density
    n_cur = n_next;
    l_cur = l_next;
end
%% plotting
figure('name','n');
plot(n','LineWidth',2);
legend('n_1','n_2','n_3')
figure('name','l');
plot(l','LineWidth',2);
legend('l_1','l_2','l_3')
figure('name','f');
plot(f','LineWidth',2);
legend('f_1','f_2','f_3')
figure('name','r');
plot(r','LineWidth',2);
legend('r_1','r_3')
figure('name','x');
plot(x','LineWidth',2);
legend('x_1','x_2','x_3')
%%
TTT = sum(sum(n)) + sum(sum(l));
TTD = sum(sum(f)) + sum(sum(r));
%%
U = sum(sum(log(r(:,end))));