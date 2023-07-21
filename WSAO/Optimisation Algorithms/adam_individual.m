classdef adam_individual < Solver
  properties
    grad                % grad vector
    h = 0.1            % step used to calculate grad = |dr|
    V
    S
    Vcorr               % means corrected
    Scorr    
    learningRate = 0.04  % Convergence rate
    beta1 = 0.9       % 1st ord momentum term
    beta2 = 0.999     % 2nd ord momentum term
    epsilon = 10^(-8)      % Small # to avoid div by 0
    iteration = 0       % iteration counter
    update
    decay_rate = 0.97
  end
  methods
    function obj = adam_individual(dims,fhandle)
      obj.dimensions = dims;
      a = zeros(dims,1);
      obj.grad = a;obj.V = a;obj.S = a;obj.Vcorr = a;obj.Scorr = a;obj.update = a;
      obj.cost_function = fhandle;
      obj.position = zeros(dims,1);
      obj.cost = obj.cost_function(obj.position);
    end

    function getGrad(obj,act_num)
        initialCost = obj.cost;
        newPos = obj.position;
        newPos(act_num) = newPos(act_num) + obj.h;
        newPos(newPos<-1) = -1;
        newPos(newPos>1) = 1;
        finalCost = obj.cost_function(newPos);    
        obj.grad(act_num) = (finalCost-initialCost)/obj.h;
    end
    
    function step(obj)
      obj.iteration = obj.iteration + 1;
      for i = 1:obj.dimensions
          getGrad(obj,i);
          % fancy stuff to calculate best direction to move in
          obj.V(i) = obj.beta1*obj.V(i) + (1-obj.beta1)*obj.grad(i);
          obj.S(i) = obj.beta2*obj.S(i) + (1-obj.beta2)*obj.grad(i).^2;
          obj.Vcorr(i) = obj.V(i)/(1-obj.beta1^obj.iteration);
          obj.Scorr(i) = obj.S(i)/(1-obj.beta2^obj.iteration);
          obj.update(i) = obj.Vcorr(i)/(sqrt(obj.Scorr(i)) + obj.epsilon);
          obj.position(i) = obj.position(i) - obj.learningRate*(obj.Vcorr(i)/(sqrt(obj.Scorr(i)) + obj.epsilon));
          obj.position(obj.position < -1) = -1; % stop voltage going beyond limits
          obj.position(obj.position > 1) = 1;
          obj.cost = obj.cost_function(obj.position);
      end
     % obj.h = obj.h * 0.9;
      obj.learningRate = obj.learningRate * obj.decay_rate;
      
    end
    function reset_solver(obj)
      obj.position(:) = 0;
      obj.V = 0;
      obj.S = 0;
      obj.iteration = 0;
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