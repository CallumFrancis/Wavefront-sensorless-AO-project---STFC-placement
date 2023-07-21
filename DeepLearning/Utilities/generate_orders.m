%% Generates orders in a range
function [N,M] = generate_orders(start,final)
    N = []; M = [];
    for i = start:final
        N = [N, i*ones(1,i+1)];
        M = [M, -i:2:i];
    end
end