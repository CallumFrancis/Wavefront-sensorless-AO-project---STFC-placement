classdef pattern_search < Solver
    properties
        search_points           % cost sample points around centre point.
        vertex_size =  1      % initial length of verteces from centroid.
        shrink_rate = 0.5      % convergance rate from 0 to 1.
    end
    methods
        function obj = pattern_search(dims,costfun)
            obj.dimensions = dims;
            obj.cost_function = costfun;
            obj.position = zeros(dims,1);
            obj.cost = obj.cost_function(obj.position);
            obj.evaluations = 1;
        end
        
        function generate_points(obj)
            positive_points = obj.vertex_size*eye(obj.dimensions) * 0.3;
            negative_points = -positive_points;
            obj.search_points = [positive_points,negative_points] + obj.position;
        end
        
        function pos = step(obj)
            generate_points(obj);
            cost_neighbours = zeros(2*obj.dimensions,1);
            
            for k = 1:2*obj.dimensions   
                if (any(obj.search_points(:,k) > 1,'all') || any(obj.search_points(:,k) < -1,'all'))
                    cost_neighbours(k) = inf;
                else
                    cost_neighbours(k) = obj.cost_function(obj.search_points(:,k));
                end
                obj.evaluations = obj.evaluations + 1;
            end
            [min_search_cost,idx] = min(cost_neighbours);
            if obj.cost <= min_search_cost
                obj.vertex_size = obj.vertex_size*obj.shrink_rate;
            else
                obj.position = obj.search_points(:,idx);
                obj.cost = min_search_cost;
            end
            pos = obj.position;
        end
        
        function settings(obj,varargin)
            prop_array = [
                obj.vertex_size;
                obj.shrink_rate
                ];
            idx = ~cellfun(@isempty,varargin);
            for i = 1:nargin-1
                if idx(i)
                    prop_array(i) = varargin{i};
                end
            end
            obj.vertex_size = prop_array(1);
            obj.shrink_rate = prop_array(2);
        end
        
        function reset(obj,varargin)
            if nargin == 1
                vert_size = 0.5;
            else
                vert_size = varargin{1};
            end
            obj.position = zeros(obj.dimensions,1);
            obj.cost = obj.cost_function(obj.position);
            obj.evaluations = 1;
            obj.vertex_size = vert_size;
        end
        
    end
end