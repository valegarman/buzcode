function [comodulogram] = bz_CFCPhaseAmp(lfp,phaserange,amprange,varargin)
% [comodulogram] = bz_CFCPhaseAmp(lfp,phaserange,amprange,flagPlot)
%
%
%This function calculates the modulation index of phase-amplitude between
%phase range (lower frequencies) to amplitude range (higher frequencies).
%It can really take a long time if you do very small steps of frequency,
%due to wavelet/filtering processing each frequency at a time.
%
%%INPUT
%    lfp            a buzcode structure with fields lfp.data,
%                                                   lfp.timestamps
%                                                   lfp.samplingRate
%                                                   lfp.channels
%                   
%    phaserange     [min:steps:max] array of frequencies to filter for the
%                   phase signal
%    amprange       [min:steps:max] array of frequencies range for wavelets
%                   for the power signal
%    <options>      optional list of property-value pairs (see table below)
%
%    =========================================================================
%     Properties    Values
%    -------------------------------------------------------------------------
%     phaseCh      channel to compute phase. If empty take first channel
%     ampChans     channels to compute amplitude. If empty take first channel
%     method       ['wavelet'(default)|'hilbert']. Method to extract power
%        of specific bands, using wavelet (default) or hilbert
%     
%     makePlot      default true
%     filterType    default 'fir1'. Method of filtering for the phase
%        bands, in case of method = 'hilbert' it also defines the filter of
%        bands in the amplitude range.
%     filterOrder   default 4. Order of the filter used for the phase
%        bands, in case of method = 'hilbert' it also defines the filter order of
%        bands in the amplitude range.
%     numBins       default 50. Number of bins to calculate the
%        Amplitude/Phase distribution.
%    =========================================================================
%
%OUTPUT
%   comodulogram.comod              phase-frequency x amplitude-frequency x 
%           ch  comodulogram matrix in modulation index units
%   comodulogram.phase_bincenters   phase bin centers
%   comodulogram.amp_bincenters     amp bin centers
%   comodulogram.params.method      method used to extract the amplitude
%   comodulogram.params.filter      filter type 
%   comodulogram.params.filterOrder filter order
%
%Dependencies
%   bz_Filter
%   bz_WaveSpec
%
%   Eliezyer de Oliveira 2018
%   AntonioFR, 2/2019
%
%
%   Last Update: 31/10/2019

%TO DO: [] adapt cell/matrix lfp inputs to buzcode lfp format


%% Parse inputs

p = inputParser;
addParameter(p,'phaseCh',lfp.channels(1),@isnumeric);
addParameter(p,'ampChans',lfp.channels(1),@isnumeric);
addParameter(p,'samplingRate',1250,@isnumeric);
addParameter(p,'makePlot',true,@islogical);
addParameter(p,'filterType','fir1',@ischar);
addParameter(p,'filterOrder',4,@isnumeric);
addParameter(p,'numBins',50,@isnumeric);
addParameter(p,'method','wavelet',@ischar);

parse(p,varargin{:});
phaseCh = p.Results.phaseCh;
ampChans = p.Results.ampChans;
samplingRate = p.Results.samplingRate;
makePlot = p.Results.makePlot;
filterType = p.Results.filterType;
filterOrder = p.Results.filterOrder;
numBins = p.Results.numBins;
method = p.Results.method;

%% this if structure needs to be adjusted to turn the cell/matrix lfp inputs to lfp format
% for now i'll leave it commented (EFO)


%lfp input
% if isstruct(lfp)
%     data = lfp.data;
%     timestamps = lfp.timestamps;
%     samplingRate = lfp.samplingRate;
% elseif iscell(lfp) %for multiple trials %% the following elseifs need to adapt the code to a lfp format of buzcode (EFO)
%     celllengths = cellfun(@length,lfp);
%     data = vertcat(lfp{:});
% elseif isnumeric(lfp)
%     data = lfp;
%     timestamps = [1:length(lfp)]'./samplingRate;
% end

%% Filter LFP for phase
for bnd = 1:length(phaserange)-1
    filtered_phase(bnd) = bz_Filter(lfp,'passband',phaserange(bnd:bnd+1),'filter',filterType,'order',filterOrder,'channels',phaseCh);
end

%% getting 
switch(method)
    
    case 'wavelet'
        %% Wavelet Transform LFP in intervals
        for ch = 1:length(ampChans)
            comod = zeros(length(amprange)-1,length(filtered_phase),length(ampChans));
            
            for apr = 1:length(amprange)-1
                wavespec_amp = bz_WaveSpec(lfp,'frange',[amprange(apr:apr+1)],'nfreqs',1,'chanID',ampChans(ch));
                
                
                amplitude_data = abs(wavespec_amp.data);
                %% Bin phase and power
                
                phasebins = linspace(-pi,pi,numBins+1);
                
                for idx = 1:length(filtered_phase)
                    [~,~,phaseall] = histcounts(filtered_phase(idx).phase,phasebins);
                    
                    phaseAmp = zeros(numBins,1);
                    for bb = 1:numBins
                        phaseAmp(bb) = mean(amplitude_data(phaseall==bb),1);
                    end
                    
                    phaseAmp = phaseAmp./sum(phaseAmp,1);
                    comod(apr,idx,ch) = sum(phaseAmp.*log(phaseAmp./(ones(numBins,size(phaseAmp,2))/numBins)))/log(numBins);
                end
                
            end
            %     ampfreqs = wavespec_amp.freqs;
            clear lfpCh
        end

    case 'hilbert'
        %% Power by hilbert transform in filtered lfp
        for ch = 1:length(ampChans)
            comod = zeros(length(amprange)-1,length(filtered_phase),length(ampChans));
            
            for apr = 1:length(amprange)-1
                lfp_amp = bz_Filter(lfp,'passband',[amprange(apr:apr+1)],'filter',filterType,'order',filterOrder,'channels',ampChans(ch));
                
                amplitude_data = lfp_amp.amp;
                %% Bin phase and power
                
                phasebins = linspace(-pi,pi,numBins+1);
                
                for idx = 1:length(filtered_phase)
                    [~,~,phaseall] = histcounts(filtered_phase(idx).phase,phasebins);
                    
                    phaseAmp = zeros(numBins,1);
                    for bb = 1:numBins
                        phaseAmp(bb) = mean(amplitude_data(phaseall==bb),1);
                    end
                    
                    phaseAmp = phaseAmp./sum(phaseAmp,1);
                    comod(apr,idx,ch) = sum(phaseAmp.*log(phaseAmp./(ones(numBins,size(phaseAmp,2))/numBins)))/log(numBins);
                end
                
            end

        end
end

comodulogram.comod = comod;
comodulogram.phase_bincenters = phaserange(1:end-1)+(diff(phaserange)/2);
comodulogram.amp_bincenters = amprange(1:end-1)+(diff(amprange)/2);
comodulogram.params.method = method;
comodulogram.params.filter = filterType;
comodulogram.params.filterOrder = filterOrder;

%% Plot
if makePlot
    
    figure
    for ch = 1:length(ampChans)
        subplot(1,length(ampChans),ch);
        contourf(comodulogram.phase_bincenters,comodulogram.amp_bincenters,abs(comodulogram.comod(:,:,ch)),20,'LineColor','none');
        y = colorbar ('SouthOutside'); colormap jet;
        xlabel(y,'CFC strength')
        ylabel('Amplitude Frequency (Hz)')
        xlabel('Phase Frequency (Hz)')
        %title(signals)
        if ch > 1
            set(gca,'YTick',[]);
        end
    end
    
end

