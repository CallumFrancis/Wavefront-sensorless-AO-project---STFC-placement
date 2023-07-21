classdef ant_colony < Solver
    properties
        N
        v
        epsilon = 0.1;
        p
        idx_pathway
        ants
        v_upper
        v_lower
        t
        v_pathway
        rho
        t_max = 1;
        t_min = 0.05;
        h
        rho_min = 0.5;
        sf = 0.75;
    end

    methods
        function self = ant_colony(dim,fhandle)
            self.dimensions = dim;
            self.cost_function = fhandle;
            self.N = 6;
            %self.cost = self.cost_function(0);
            self.cost = inf;
            self.ants = 20;
            self.reset();
            self.rho = 0.75;

        end
        
        function reset(self)
            self.v_upper = 0.1*ones(self.dimensions,1); % upper voltage for each actuator 
            self.v_lower = - 0.1*ones(self.dimensions,1); % lower voltage for each actuator
            
        end

        function step(self) % voltages all between -1 and 1 so algorithm can be scaled to different mirrors
            self.t = 0.05 * ones(self.dimensions,self.N +1); % trail intensity initially set to 0.05
            self.cost = inf;
            self.h = (self.v_upper - self.v_lower)/self.N; % divide each actuator voltage into N+1 parts
            self.v = zeros(self.dimensions,self.N +1); 
            self.v_pathway = zeros(self.ants,self.dimensions);
            self.idx_pathway = zeros(size(self.v_pathway));
            v_positions = 1:self.N +1;

            if max(self.h,[],'all') < self.epsilon
                v_opt = (self.v_upper + self.v_lower)/2;
            end
            mincost = inf;
            for count = 1:12
                self.cost = inf;

                for j = 1:self.dimensions
                    for i = 1:self.N +1

                        self.p(j,i) = self.t(j,i) / sum(self.t(j,:)); % generate probablities for each actuator
                    end
                    for k = 1:self.ants

                        self.idx_pathway(k,j) = randsample(v_positions,1,true,self.p(j,:)); % generate pathways for k ants
                        self.v_pathway(k,j) = self.v_lower(j) + self.h(j) * (self.idx_pathway(k,j)-1); % there is a pathway of voltages and their indexes
                    end

                end

            
            for k = 1:self.ants
               cost = self.cost_function(transpose(self.v_pathway(k,:))); % find cost of each pathway
               if cost < mincost
                   bestest_ant = self.idx_pathway(k,:);
                   bestest_path= self.v_pathway(k,:);
                   mincost = cost;
                   
                end
            end
           

        

            % update best ant's trail
            self.t = self.t * (1 - self.rho); % I decided to apply evaporation to all of them but idk if thats right

            for j = 1:self.dimensions
                self.t(j,bestest_ant(j)) = self.t(j,bestest_ant(j))  + (1/(mincost*20)); % subtract cost as it is negative
            end
            
            self.t(self.t > 1.2) = 1.2;
            self.t(self.t < 0.05) = 0.05;
            end

            
            %self.update_voltages(bestest_ant)
            self.update_voltages(bestest_path);
            % update voltages
            % repeat set number of times
            self.cost = mincost;
            if 0.95 * self.rho > self.rho_min
                self.rho = 0.95 * self.rho; % rate of decay decreases over time
            else
                self.rho = self.rho_min;
            end
            self.position = bestest_path;
            
        end

        function update_voltages(self,bestest_path)
            new_range = (self.v_upper - self.v_lower) * self.sf; % decrease range of each actuator by scale factor
            new_upper = bestest_path' + new_range/2;
            new_lower = bestest_path' - new_range/2;
            new_upper(new_upper > 1) = 1;
            new_lower(new_lower < -1) = -1;
            self.v_upper = new_upper;
            self.v_lower = new_lower;


        end
    end
end

