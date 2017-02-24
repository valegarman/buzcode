function [Stat data_all] = findPattern(S,is)

nbCells = length(S);
nbSt = length(Start(is));
nullEvt = 0;

for i=1:nbSt

	wh = waitbar(i/nbSt);

	is0 = subset(is,i);
	data = [];

	for j=1:nbCells

		rg = Range(Restrict(S{j},is0));
		l = length(rg);
		if l>0
			rg = rg - Start(is0);
			rg = rg/10000; %in sec!
			data = [data ;[rg ones(l,1)*j]];
		end

	end

	if size(data,2)>0 & sum(diff(data(:,2)))> 0 %keep events with at least 2 cells spiking

		[V,I] = sort(data(:,1));
		data_all{i-nullEvt} = [V data(I,2)]';

	else
		nullEvt = nullEvt+1;
	end

	

end

close(wh);

nbTrials = length(data_all);

%  keyboard

eta                                 = 5;
Input.Trials                        = nbTrials;
Input.GDF_all_trials                = data_all;
Input.Window                        = [0 0.1];                        % Data between 1.5 and 3 sec is coorelated
Input.Nr_Neurons                    = nbCells;
Input.dt                            = 1/10^3;                           % Resolution of your Data
Input.Max_Nr_Jitter_Points          = 5;                                % Tau_C in units of Input.dt - Timescale of Joint Spike Events
Input.Jittering_for_sig             = eta*Input.Max_Nr_Jitter_Points ;  % Tau_R in units of Input.dt - Lower bound of Timescale of Rate co-variations 
Input.Nr_Surrogate                  = 20;                               % Number ofSurrogates
Input.test_level                    = 0.01;                             % Testlevel
Input.flag_both_jitter              = 0;                                % Destroys structure in the surrogate as well as in the original dataset- Must be used to  estimate efects under H0
Stat                    = NeuroXidence_Windowed_V22(Input);


