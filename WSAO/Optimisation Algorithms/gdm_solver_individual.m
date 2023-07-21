classdef gdm_solver_individual < Solver
    % Gradient descent with momentum. Inherits from solver
    properties
        momentum = 0.1
        gradient = inf
        learningRate = 0.0001
        gradstep = 0.1
        L2       = 0
        weightedgrad = 0.05
        decay_rate = 0.97
    end


    methods
        function obj = gdm_solver_individual(dims,costfun)
            obj.dimensions = dims;
            obj.position = zeros(dims,1);
            obj.gradient = zeros(dims,1);
            obj.cost_function = @(r)costfun(r) + obj.L2*sum(r.^2,'all');
            obj.cost = obj.cost_function(obj.position);
            obj.reset();
        end
        function getGrad(obj,act_num)
            initialCost = obj.cost;
            newPos = obj.position;
            newPos(act_num) = newPos(act_num) + obj.gradstep;
            newPos(newPos<-1) = -1;
            newPos(newPos>1) = 1;
            finalCost = obj.cost_function(newPos);
            obj.gradient(act_num) = (finalCost-initialCost)/obj.gradstep;

        end
        function step(obj)
            for i = 1:obj.dimensions
                getGrad(obj,i)
                obj.weightedgrad = obj.momentum*obj.weightedgrad +...
                    (1-obj.momentum)*obj.gradient;
                obj.position = obj.position - obj.learningRate*obj.weightedgrad;
                obj.position(obj.position < -1) = -1;
                obj.position(obj.position > 1) = 1;
                obj.cost = obj.cost_function(obj.position);
            end
        obj.learningRate = obj.learningRate * obj.decay_rate;
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
