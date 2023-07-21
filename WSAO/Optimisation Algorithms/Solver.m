classdef (Abstract) Solver < handle
    % Abstract class for optimisation algorithms
    % All algorithms inherit these properties
    properties
        position                % Position in parameter space
        maxI_pos                % Positions with maximum intensity
        cost_function           % Function handle to objective function
        cost                    % Current cost
        dimensions              % Number of dimensions
        evaluations    % delete me
    end
    methods
        pos = step(self)        % Step solver
        settings(self)          % Set solver parameters
        reset(self)             % Reset/Reinitialise solver
    end
end