classdef adam < Solver
  properties
    grad                % grad vector
    h = 0.1            % step used to calculate grad = |dr|
    V = 0
    S = 0
    Vcorr               % means corrected
    Scorr    
    learningRate = 0.3  % Convergence rate
    beta1 = 0.9       % 1st ord momentum term
    beta2 = 0.999     % 2nd ord momentum term
    epsilon = 10^(-8)      % Small # to avoid div by 0
    iteration = 0       % iteration counter
    update
  end
  methods
    function obj = adam(dims,fhandle)
      obj.dimensions = dims;
      obj.cost_function = fhandle;
      obj.position = zeros(dims,1);
      obj.cost = obj.cost_function(obj.position);

    end
    function getGrad(obj)
      finalCost = zeros(obj.dimensions,1);
      initialCost = obj.cost;
      H = eye(obj.dimensions) * obj.h;

      for i = 1:obj.dimensions
        newPos = obj.position + H(:,i);
        newPos(newPos<-1) = -1;
        newPos(newPos>1) = 1;
        finalCost(i) = obj.cost_function(newPos);
      end
      obj.grad = (finalCost-initialCost)/obj.h;
    end
    function step(obj)
      obj.iteration = obj.iteration + 1;
      getGrad(obj);
      % fancy stuff to calculate best direction to move in
      obj.V = obj.beta1*obj.V + (1-obj.beta1)*obj.grad;
      obj.S = obj.beta2*obj.S + (1-obj.beta2)*obj.grad.^2;
      obj.Vcorr = obj.V/(1-obj.beta1^obj.iteration);
      obj.Scorr = obj.S/(1-obj.beta2^obj.iteration);
      obj.update = obj.Vcorr./(sqrt(obj.Scorr) + obj.epsilon);
      obj.position = obj.position - obj.learningRate*(obj.Vcorr./(sqrt(obj.Scorr) + obj.epsilon));
      idx1 = obj.position < -1;
      idx2 = obj.position > 1;
      obj.position(idx1) = -1; % stop voltage going beyond limits
      obj.position(idx2) = 1;
      obj.cost = obj.cost_function(obj.position);
      obj.learningRate = obj.learningRate * 0.98;
    end
    
    function reset_solver(obj)
      obj.position(:) = 0;
      obj.V = 0;
      obj.S = 0;
      obj.iteration = 0;
      obj.mirror_moves = 0;
    end


    function settings(obj,varargin)
        % Arguments: 1.learningRate, 2.beta1, 3.beta2, 4.grad_step
        prop_array = [
            obj.learningRate;
            obj.beta1;
            obj.beta2;
            obj.h;
            ];
        idx = ~cellfun(@isempty,varargin);
        for i = 1:nargin-1
            if idx(i)
                prop_array(i) = varargin{i};
            end
        end
        obj.learningRate = prop_array(1);
        obj.beta1        = prop_array(2);
        obj.beta2        = prop_array(3);
        obj.gradStep     = prop_array(4);
    end
  end
end