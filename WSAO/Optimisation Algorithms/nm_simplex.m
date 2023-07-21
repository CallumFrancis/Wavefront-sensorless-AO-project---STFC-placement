
%% Nelder–Mead simplex method
classdef nm_simplex < Solver
    properties
        simplex
        simplex_cost
        init_size = 0.05;
        upper_lim = 1;
        lower_lim = -1;

        r_coeff = 1.5 % reflection
        e_coeff = 2 % expansion
        c_coeff = 0.5 % contraction
        s_coeff = 0.5 % shrinkage
    end
    methods
        
        function self = nm_simplex(dims,costfun)
            self.dimensions = dims;
            self.cost_function = costfun;
            self.reset();
        end
        
        function reset(self)
            N = self.dimensions;
            init_position = zeros(N,1);
            % nms = self.init_size*eye(N) + init_position; % why just add 0

            test_points = randi([-1000 1000], N)/100000;
            self.simplex = cat(2,test_points,init_position); % just adds the initial position to the end
            self.simplex_cost = self.array_cost(self.simplex);
            self.position = init_position;
        end
        
        function step(self,varargin)
            % See wikipedia on nelder mead simplex method for algorithm
            steps = 20;
            if ~isempty(varargin) % don't know what the varargin is for
                steps = varargin{1};
            end



            for i = 1:steps
                self.sort_simplex();

                sec_to_worst_cost = self.simplex_cost(end-1); % record some important cost values
                best_cost = self.simplex_cost(1);

                centroid = self.get_centroid(); 

                reflected = self.get_reflected(centroid); % find reflection of worst point through centroid
                reflected_cost = self.array_cost(reflected);
                
                if reflected_cost < sec_to_worst_cost && reflected_cost >= best_cost % if reflected cost better than second worst but not better than the best
                    self.simplex(:,end) = reflected; % replace worst point with reflected point and repeat
                    self.simplex_cost(end) = reflected_cost;

                elseif reflected_cost < best_cost % if reflected point is best so far
                    expanded = self.get_expanded(centroid,reflected); % compute the expanded point
                    expanded_cost = self.array_cost(expanded);
                    if expanded_cost < reflected_cost % if expanded is better than the reflected
                        self.simplex(:,end) = expanded; % replace worst point with expanded point and repeat
                        self.simplex_cost(end) = expanded_cost;

                    else
                        self.simplex(:,end) = reflected; % else replace worst point with reflected point and repeat
                        self.simplex_cost(end) = reflected_cost;

                    end
                else % reflected point worse than second worst point
                    worst_cost = self.simplex_cost(end); % worst cost


                    if reflected_cost < worst_cost % find the slightly better between reflected and worst point
                        not_worst_cost = reflected_cost;
                    else
                        not_worst_cost  = worst_cost;
                    end
                    contracted = get_contracted(self,centroid); % compute the contracted point
                    contracted_cost = self.array_cost(contracted); 
                    if contracted_cost < not_worst_cost
                        self.simplex(:,end) = contracted; % if contracted better than the not worst, replace worst and repeat
                        self.simplex_cost(end) = contracted_cost;

                    else
                        self.shrink_simplex();

                    end
                end
                self.position = self.simplex(:,1);
                self.cost = self.simplex_cost(1);
            end
        end
        
        function sort_simplex(self)
            % Sorting in ascending order: lower cost first (best < worst)
            %self.simplex_cost = self.evaluate(self.simplex);
            [self.simplex_cost,idx] = sort(self.simplex_cost);
            self.simplex = self.simplex(:,idx);
        end
        
        function cost = array_cost(self,points) % cos it can take arrays
            % Evaluates a single point or set of points
            % Must be N by M matrix where M is number of points
            num_points = size(points,2);
            cost = zeros(1,num_points);
            for idx = 1:num_points
                cost(idx) = self.cost_function(points(:,idx));
            end
        end
        
        function centroid = get_centroid(self)
            % Centroid of all points besides worst
            centroid = mean(self.simplex(:,1:end-1),2);
        end
        
        function reflected = get_reflected(self,centroid)
            % Reflection of worst from the centroid
            worst = self.simplex(:,end);
            reflected = centroid + self.r_coeff*(centroid-worst);
            self.limits()
        end
        
        function expanded = get_expanded(self,centroid,reflected)
            % Expanding reflected point
            expanded = centroid + self.e_coeff*(reflected-centroid);
            self.limits()
        end
        
        function contracted = get_contracted(self,centroid)
            % Contraction. Point between worst & centroid
            worst = self.simplex(:,end);
            contracted = centroid + self.c_coeff*(worst - centroid);
            self.limits()
        end
        
        function shrink_simplex(self)
            best = self.simplex(:,1);
            for i = 2:self.dimensions
                current = self.simplex(:,i);
                self.simplex(:,i) =best + self.s_coeff*(current - best);
            end
            self.limits()
        end

        function limits(self)
            self.simplex(self.simplex < self.lower_lim) = self.lower_lim;
            self.simplex(self.simplex > self.upper_lim) = self.upper_lim;
        end

        function settings(self,varargin)
            prop_array = [
                self.init_size;
                self.r_coeff;
                self.e_coeff;
                self.c_coeff;
                self.s_coeff;
                ];
            idx = ~cellfun(@isempty,varargin);
            for i = 1:nargin-1
                if idx(i)
                    prop_array(i) = varargin{i};
                end
            end
            self.init_size = prop_array(1);
            self.r_coeff = prop_array(2);
            self.e_coeff = prop_array(3);
            self.c_coeff = prop_array(4);
            self.s_coeff = prop_array(5);
        end
        
    end
end