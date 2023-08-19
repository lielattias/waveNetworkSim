classdef Channel < handle 
    
    properties (SetAccess = private)
        SNRmatrix                    % ground truth - SNR between each pair of RUs
        SNRGatewayMatrix             % ground truth - SNR between each RU and the GW
        FreqCHList                   % a list of freqCH  

        PER                          % packet error rate
        BER                          % bit error rate
    end
    
    methods (Static)
       % define persistent variables:
       % GeneralParam
       % since those are the same for all instances

       function out = setgetGeneralParams(generalParams)
           persistent GeneralParams;
           if nargin
               GeneralParams = generalParams;
           end
           out = GeneralParams;
       end
   end

    methods
        function obj = Channel(SNRmatrix, SNRGatewayMatrix)
            obj.FreqCHList = struct('RUsource', cell(0), 'packet', cell(0));
            if (nargin == 2)
                obj.SNRmatrix = SNRmatrix;
                obj.SNRGatewayMatrix = SNRGatewayMatrix;
            end
            obj.PER = load('PER.mat').packetLossErrorRate;
            % obj.BER = load()...
        end

        % write/read to/from channel 
        function obj = writeToChannel(obj, packet, freqCHIndex, RUsource)
            obj.FreqCHList(freqCHIndex) = struct('RUsource', RUsource, 'packet', packet);
        end

        function [packet] = readFromChannel(obj, freqCHIndex, RUdestination)
            GeneralParams = obj.setgetGeneralParams();

            % here, we know the source and the destination, thus, we can
            % flip the bits properly 

            % extract RUsource and packet from the desired freqCHIndex
            RUsource = obj.FreqCHList(freqCHIndex).RUsource;
            packet = obj.FreqCHList(freqCHIndex).packet;
            if RUdestination == 0 
                SNR = obj.SNRGatewayMatrix(RUsource);
            elseif RUsource == 0
                SNR = obj.SNRGatewayMatrix(RUdestination);
            else
                SNR = obj.SNRmatrix(RUsource, RUdestination);
            end


            % "packet-wise"
            ber = obj.PER(SNR+1); 
            
            % "bit-wise"
            % if isHW....

            isflipped = ber > rand();
            
            % maybe this should be a the RemoteUnit class
            if isflipped
                % all the previous data should be earased, a new packet is
                % created 
                
                fprintf("CRC failed - packet got earased\n");

                if isa(packet, 'ULMessage')
                    packet = ULMessage();
                elseif isa(packet, 'DLMessage')
                    packet = []; % if the packet got corrupted, the rest of the chain will not have any information
                end
            end

            % delete the packet from the channel
            obj.FreqCHList(freqCHIndex) = struct('RUsource', [], 'packet', []);
        end

    end
end