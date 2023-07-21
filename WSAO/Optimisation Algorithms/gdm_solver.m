classdef gdm_solver < Solver
    % Gradient descent with momentum. Inherits from solver
    properties
        momentum = 0.1
        gradient = inf
        learningRate = 0.3
        gradstep = 0.1
        L2       = 0
        weightedgrad = 0.05
    end


    methods
        function obj = gdm_solver(dims,costfun)
            obj.dimensions = dims;
            obj.position = zeros(dims,1);
            obj.cost_function = @(r)costfun(r) + obj.L2*sum(r.^2,'all');
            obj.reset();
        end
        function pos = step(obj)
            obj.cost = obj.cost_function(obj.position);
            pos2 = obj.gradstep*eye(obj.dimensions) + obj.position;
            cost2 = zeros(obj.dimensions,1);
            for i = 1:obj.dimensions
                cost2(i) = obj.cost_function(pos2(:,i))';
            end
            obj.gradient = (cost2-obj.cost)/obj.gradstep;
            obj.weightedgrad = obj.momentum*obj.weightedgrad +...
                (1-obj.momentum)*obj.gradient;
            obj.position = obj.position - obj.learningRate*obj.weightedgrad;
            obj.position(obj.position < -1) = -1;
            obj.position(obj.position > 1) = 1;
            pos = obj.position;
            obj.learningRate = obj.learningRate * 0.93;
        end
        function settings(obj,varargin)
            % Leave argument as [] if you don't want to change it
            prop_array = [
                obj.learningRate;
                obj.momentum;
                obj.gradstep;
                obj.L2;
                ];
            idx = ~cellfun(@isempty,varargin);
            for i = 1:nargin-1
                if idx(i)
                    prop_array(i) = varargin{i};
                end
            end
            obj.learningRate = prop_array(1);
            obj.momentum = prop_array(2);
            obj.gradstep = prop_array(3);
            obj.L2       = prop_array(4);
        end
        function reset(obj)
            obj.position = zeros(obj.dimensions,1);
            obj.cost = inf;
            obj.weightedgrad = 0;
        end
    end
end
