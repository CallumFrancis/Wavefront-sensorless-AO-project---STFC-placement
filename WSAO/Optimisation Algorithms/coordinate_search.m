classdef coordinate_search < Solver
    properties
        sMatrix
        srange
        origin
        samples = 5;
    end
    
    methods
        function self = coordinate_search(dim,fhandle,varargin)
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
            
            if nargin == 2
                self.position = varargin{1};
            else
                self.position = zeros(self.dimensions,1);
            end
            self.origin = self.position;
            self.cost = self.cost_function(self.position);
        end
        function step(self)
           
            mincost = self.cost;
            for i = 1:self.dimensions
                xvals = linspace(self.srange(1,i),self.srange(2,i),self.samples);
                self.sMatrix = self.origin + zeros(self.dimensions,self.samples); % 36x5
                
                idx=0;
                for j = 1:self.samples
                    
                    self.sMatrix(i,j) = xvals(j);
                    self.cost = self.cost_function(self.sMatrix(:,j)); % find cost of this new set of positions
                    self.evaluations = self.evaluations + 1;
                    if self.cost <= mincost % if new cost is lower
                        mincost = self.cost; % record as minimum cost
                        idx = j;
                    end
                end
                
                if idx == 0
                    fprintf(':(');
                else
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
                end
                self.origin = self.position;
            end
            self.cost = mincost;
        end
    end
end