classdef coordinate_search_orig < Solver
    properties
        sMatrix
        srange
        origin
        samples = 5;
        idx_backup % in case no search position has a lower cost
        mincost
    end
    
    methods
        function self = coordinate_search_orig(dim,fhandle,varargin)
            if nargin == 3
                self.samples = varargin{1};
            end
            self.dimensions = dim;
            self.cost_function = fhandle;
            self.reset();
        end
        function reset(self,varargin)
            % Optional argument specifies initial position
            self.srange = [-ones(1,self.dimensions);ones(1,self.dimensions)]; %creates 2x36 double 
            self.cost = inf;
            %self.cost = inf(self.samples,1);
            if nargin == 2
                self.position = varargin{1};
            else
                self.position = zeros(self.dimensions,1);
            end
            self.origin = self.position;
            self.mincost = inf;
        end
        function step(self)
            for i = 1:self.dimensions
                xvals = linspace(self.srange(1,i),self.srange(2,i),self.samples);
                self.sMatrix = self.origin + zeros(self.dimensions,self.samples); % 36x5
                for j = 1:self.samples
                    self.sMatrix(i,j) = xvals(j);
                    self.cost(j) = self.cost_function(self.sMatrix(:,j));
                    self.evaluations = self.evaluations + 1;
                    if self.cost(j) <= self.mincost
                        self.mincost = self.cost(j);
                        idx = j;
                    end
                end
               
                exist idx var
                if ans == 0
                    idx = self.idx_backup;
                end
                self.position = self.sMatrix(:,idx);
                if idx == 1 
                    self.srange(1,i) = self.sMatrix(i,idx); %changed to stop function going beyond allowed mirror voltages
                    self.srange(2,i) = self.sMatrix(i,idx +1);
                elseif idx == self.samples
                    self.srange(1,i) = self.sMatrix(i,idx-1);
                    self.srange(2,i) = self.sMatrix(i,idx);
                else
                    self.srange(1,i) = self.sMatrix(i,idx-1);
                    self.srange(2,i) = self.sMatrix(i,idx+1);
                end
                self.origin = self.position;
                self.idx_backup = idx;
            end
            self.cost = self.mincost;
        end
    end
end
