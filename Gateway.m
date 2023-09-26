classdef Gateway < handle

    properties % (SetAccess = private)
        SNRmatrix                               % estimated SNR matrix
                                                % SNR[i,j] = SNR between RU i and RU j
        % SNRmatrix for new RUs 
        BlockChainsDB                           % data structure that contains the rounting of the network
        TimeFreqMatrix                          % a matrix that contains the actions of the "associated" RUs
        BlocksLocations                         % 1st col - freqCH index
                                                % 2nd col - TS (in timefreqMat)
        NRAPList                                % a list that contains all the NRAP the GW sends to the RUs
        PayloadBits                             % payload bits - the data collected from the RUs
        NumAssociatedRUs (1,1) {mustBeInteger}
        GatewayRUs

%         ConnectedRUs  (1,:) {mustBeVector}     % a list of all the RUs the GW know of
    end
    
     methods (Static)
       % define persistent variables:
       % NetworkChannel
       % GeneralParam
       % since those are the same for all instances
       function out = setgetChannel(channel)
           persistent NetworkChannel;
           if nargin
               NetworkChannel = channel;
           end
           out = NetworkChannel;
       end

       function out = setgetGeneralParams(generalParams)
           persistent GeneralParams;
           if nargin
               GeneralParams = generalParams;
           end
           out = GeneralParams;
       end
   end

    methods
        function obj = Gateway(SNRmatrix, gatewayRUs)
            obj.NRAPList = NRAP.empty;

            % in case we want to simulate a full network 
            if nargin == 2
                obj.SNRmatrix = SNRmatrix;
                obj.GatewayRUs = gatewayRUs;
                [obj.NumAssociatedRUs, ~] = size(SNRmatrix);
            else
                obj.NumAssociatedRUs = 0;
            end
        end

        function numOfRemainingSensors = routing(obj)
            % call an external function 
            [numOfRemainingSensors, obj.BlockChainsDB] = Routing(obj.SNRmatrix, obj.GatewayRUs);       
        end

        function obj = createNRAPList(obj)
            % NRAPList construction
            isEmptyStruct = @(s) ~isequaln(s, struct('Rx',[],'RxWait',[],'Tx',[],'TxRelay',[])); 
            GeneralParams = obj.setgetGeneralParams();
            % params 
            numOfTrials = 3;
            minFrameLength = 100;
            maxFrameLength = GeneralParams.NumTsFrameMax;
            maxfreqCH = GeneralParams.NumFreqCh;
            increment = 1.2;

            frameLength = minFrameLength;
            [numOfBlocks, ~] = size(obj.BlockChainsDB);

            isScheduled = zeros(numOfBlocks, 1); % indicate which blocks got scheduled in the matrix

            ctr = 0;

            while ~isempty(find(isScheduled==0, 1)) % not all blocks were scheduled

                ctr = ctr + 1;

                % variables for the algo
                blockLocation = zeros(numOfBlocks, 2); % in which row each block was scheduled
                isScheduled = zeros(numOfBlocks, 1); % zero this array
                mixedBlockChainsDB = obj.BlockChainsDB(randperm(size(obj.BlockChainsDB, 1)), :); % shuffle the rows for better performances

                % time-freq matrix
                timefreqMatrix = struct('Rx', cell(maxfreqCH, frameLength), 'RxWait', cell(maxfreqCH, frameLength),...
                    'Tx', cell(maxfreqCH, frameLength), 'TxRelay', cell(maxfreqCH, frameLength));

                lengthsOfRows = zeros(maxfreqCH,1);

                while ~all(isScheduled) % all the elements are non-zero (all blocks were scheduled)
                    unscheduledBlocks = find(isScheduled==0);
                    isupdated = 0;

                    for i=1:length(unscheduledBlocks)
                        currentBlock = mixedBlockChainsDB(unscheduledBlocks(i),:);
                        lengthOfCurrentBlock = sum(arrayfun(isEmptyStruct,currentBlock));

                        % find all rows (indexes) this block might fit into
                        rowIndexes = find(lengthsOfRows + lengthOfCurrentBlock < frameLength);

                        % add 0 in final Rx for GW to know
                        currentBlock(lengthOfCurrentBlock).Rx = 0;

                        if ~isempty(rowIndexes)
                            currentRowIndex = rowIndexes(1);
                            isintersect = 0;

                            % make sure there are no intersections, i.e., a RU operates at the same TS in different freqs.
                            for j=1:lengthOfCurrentBlock
                                RUsNode = unique([currentBlock(j).Rx, currentBlock(j).RxWait, currentBlock(j).Tx, currentBlock(j).TxRelay]);
                                col = timefreqMatrix(:, lengthsOfRows(currentRowIndex) + j);
                                RUsCol = unique([col.Rx, col.RxWait, col.Tx, col.TxRelay]);
                                if ~isempty(intersect(RUsCol, RUsNode))
                                    isintersect = 1;
                                    break;
                                end
                            end

                            if ~isintersect
                                isupdated = 1;
                                timefreqMatrix(currentRowIndex, lengthsOfRows(currentRowIndex)+1:lengthsOfRows(currentRowIndex)+lengthOfCurrentBlock) = currentBlock(1:lengthOfCurrentBlock);
                                lengthsOfRows(currentRowIndex) = lengthsOfRows(currentRowIndex) + lengthOfCurrentBlock;
                                isScheduled(unscheduledBlocks(i)) = 1;
                                blockLocation(unscheduledBlocks(i),:) = [currentRowIndex, lengthsOfRows(currentRowIndex)];

                            end


                            if isupdated == 0
                                % take the last block in unscheduledBlocks and schedule it by
                                % trying different rows / indentions

                                % different rows
                                if lengthsOfRows(currentRowIndex) ~= 0
                                    k = 2;
                                    if length(rowIndexes) >= k
                                        newRow = rowIndexes(k);
                                        while lengthsOfRows(newRow) ~= 0 && isintersect == 1
                                            newRow = rowIndexes(k);
                                            % make sure there are no intersections, i.e., a RU operates at the same TS in different freqs.
                                            for j=1:lengthOfCurrentBlock
                                                RUsNode = unique([currentBlock(j).Rx, currentBlock(j).RxWait, currentBlock(j).Tx, currentBlock(j).TxRelay]);
                                                col = timefreqMatrix(:, lengthsOfRows(newRow) + j);
                                                RUsCol = unique([col.Rx, col.RxWait, col.Tx, col.TxRelay]);
                                                if isempty(intersect(RUsCol, RUsNode))
                                                    isintersect = 0;
                                                    break;
                                                end
                                            end

                                            if ~isintersect
                                                isupdated = 1;
                                                timefreqMatrix(newRow, lengthsOfRows(newRow)+1:lengthsOfRows(newRow)+lengthOfCurrentBlock) = currentBlock(1:lengthOfCurrentBlock);
                                                lengthsOfRows(newRow) = lengthsOfRows(newRow) + lengthOfCurrentBlock;
                                                isScheduled(unscheduledBlocks(i)) = 1;
                                                blockLocation(unscheduledBlocks(i),:) = [newRow, lengthsOfRows(newRow)];

                                            end
                                            k = k+1;
                                        end
                                    end
                                end

                                % different indents
                                if isintersect == 1 % only if the last trial failed
                                    for indent=1:(frameLength-lengthsOfRows(currentRowIndex)-lengthOfCurrentBlock)
                                        isintersect = 0;
                                        % make sure there are no intersections, i.e., a RU operates at the same TS in different freqs.
                                        for j=1:lengthOfCurrentBlock
                                            RUsNode = unique([currentBlock(j).Rx, currentBlock(j).RxWait, currentBlock(j).Tx, currentBlock(j).TxRelay]);
                                            col = timefreqMatrix(:, lengthsOfRows(currentRowIndex) + j + indent);
                                            RUsCol = unique([col.Rx, col.RxWait, col.Tx, col.TxRelay]);
                                            if ~isempty(intersect(RUsCol, RUsNode))
                                                isintersect = 1;
                                                break;
                                            end
                                        end
                                    end
                                    if ~isintersect
                                        isupdated = 1;
                                        timefreqMatrix(currentRowIndex, lengthsOfRows(currentRowIndex)+1+indent:lengthsOfRows(currentRowIndex)+lengthOfCurrentBlock+indent) = currentBlock(1:lengthOfCurrentBlock);
                                        lengthsOfRows(currentRowIndex) = lengthsOfRows(currentRowIndex) + lengthOfCurrentBlock +indent;
                                        isScheduled(unscheduledBlocks(i)) = 1;
                                        blockLocation(unscheduledBlocks(i),:) = [currentRowIndex, lengthsOfRows(currentRowIndex)];
                                    end
                                end
                            end
                        end
                    end
                    if isupdated == 0
                        break;
                    end
                end
                
                if ctr == numOfTrials % increse frame size if schedule isn't complete
                    ctr = 1;
                    if ~isempty(find(isScheduled==0, 1))
                        if frameLength < maxFrameLength
                            frameLength = min(ceil(frameLength * increment), maxFrameLength);
                        else
                            error("schedule faild, increse maxFrameLength");
                        end
                    end
                end
            end

            % NRAP list

            obj.NRAPList(obj.NumAssociatedRUs, 1) = NRAP; % list of the NRAPs we want to build
            isEmptyNRAPfieldStruct = @(s) ~isequaln(s, struct('TS',[],'freqCH',[]));

            for freqCH = 1:max(blockLocation)
                sigIndex = 1;

                currentRow = timefreqMatrix(freqCH, :);
                for TSindex = 1:frameLength

                    currentNode = currentRow(TSindex);

                    %%%%%%%%%%%%%%%% Tx %%%%%%%%%%%%%%%%
                    if ~isempty(currentNode.Tx)
                        % the RU is first in its chain, transmit after RxWait or part of RxTx
                        if sigIndex == 1 || isempty(currentRow(TSindex-1).Rx) || ~(currentRow(TSindex-1).Rx == currentNode.Tx)
                            obj.NRAPList(currentNode.Tx).SigIndex = sigIndex; % update sigIndex

                            % update isFirstInChain
                            if sigIndex == 1
                                obj.NRAPList(currentNode.Tx).isFirstInChain = 1;
                            end
                            
                            sigIndex = sigIndex + 1;
                            obj.NRAPList(currentNode.Tx).ULTx = TSindex;
                            if obj.NRAPList(currentNode.Tx).freqChOfBlock == 0
                                obj.NRAPList(currentNode.Tx).freqChOfBlock = freqCH;
                            end
                        end

                        % the end of the chain
                        if currentNode.Rx == 0
                            sigIndex = 1;
                        end
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


                    %%%%%%%%%%%%%%% TxRelay %%%%%%%%%%%%
                    % must occur after Rx
                    % the end of the chain
                    if currentNode.Rx == 0
                        sigIndex = 1;
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


                    %%%%%%%%%%%%%%%% Rx %%%%%%%%%%%%%%%%
                    % could be RxTx or RxTxRelay, depends on the next TS
                    % ( Rx is always followed by some Tx )
                    if ~isempty(currentNode.Rx) && currentNode.Rx~=0
                        currentRU = currentNode.Rx;

                        if currentRow(TSindex + 1).Tx == currentRU % RxTx case
                            % if there is no sigIndex yet
                            if obj.NRAPList(currentNode.Rx).SigIndex == 0
                                obj.NRAPList(currentNode.Rx).SigIndex = sigIndex;
                                sigIndex = sigIndex + 1;
                            end
                            obj.NRAPList(currentNode.Rx).ULRxTx = TSindex;

                            if obj.NRAPList(currentNode.Rx).freqChOfBlock == 0
                                obj.NRAPList(currentNode.Rx).freqChOfBlock = freqCH;
                            end

                        end

                        if currentRow(TSindex+1).TxRelay == currentRU % RxTxRelay case
                            % in this case, the RU is not part of the block, we
                            % don't update the sigIndex
                            endOfULRxTxRelay = sum(arrayfun(isEmptyNRAPfieldStruct,obj.NRAPList(currentNode.Rx).ULRxTxRelay));
                            obj.NRAPList(currentNode.Rx).ULRxTxRelay(endOfULRxTxRelay + 1) = struct('TS', TSindex, 'freqCH', freqCH);
                        end
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


                    %%%%%%%%%%%%%%%%% RxWait %%%%%%%%%%%
                    if ~isempty(currentNode.RxWait)
                        % if there is no sigIndex yet
                        if obj.NRAPList(currentNode.RxWait).SigIndex == 0
                            obj.NRAPList(currentNode.RxWait).SigIndex = sigIndex;
                            sigIndex = sigIndex + 1;
                        end
                        endOfULRxWait = sum(arrayfun(isEmptyNRAPfieldStruct,obj.NRAPList(currentNode.RxWait).ULRxWait));
                        obj.NRAPList(currentNode.RxWait).ULRxWait(endOfULRxWait + 1) = struct('TS', TSindex);

                         if obj.NRAPList(currentNode.RxWait).freqChOfBlock == 0
                                obj.NRAPList(currentNode.RxWait).freqChOfBlock = freqCH;
                         end
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                end
            end

            % add frameLength to all NRAP objects
            for i=1:obj.NumAssociatedRUs
                obj.NRAPList(i).NumTsFrame = frameLength;
            end

            % save the final BlockChainsDB order
            obj.BlockChainsDB = mixedBlockChainsDB;

            % save the final time-frequency matrix 
            obj.TimeFreqMatrix = timefreqMatrix;

            % save the final blockLocation 
            obj.BlocksLocations = blockLocation;
        end

        function obj = activate(obj, direction, freqIndex, epoch)
            GeneralParams = obj.setgetGeneralParams();
            channel = obj.setgetChannel();
            % UL
            if strcmp(direction, 'UL')

                % GW receives packets & saves them
                numOfBlock = find(ismember(obj.BlocksLocations,[freqIndex, epoch],'rows'));
                if GeneralParams.SimLevel
                    obj.PayloadBits(numOfBlock,1) = str2double(channel.readFromChannel(freqIndex, 0));
                else
                    msg = channel.readFromChannel(freqIndex, 0);
%                     if isempty(obj.PayloadBits)
%                         obj.PayloadBits = zeros(GeneralParams.NumBitsPerSig, GeneralParams.NumBitsPerSig);
%                     end
                    obj.PayloadBits(numOfBlock,:) = msg.Data;
                    
                end
                fprintf("GW RECEIVED block %d\n", numOfBlock);

            % DL
            elseif strcmp(direction, 'DL')
                % create packet (for bit-wise simulation should be more detailed)
                if GeneralParams.SimLevel
                    % ???
                else
                    packet = DLMessage();
                end
                channel.writeToChannel(packet, freqIndex, 0);
                fprintf("GW TRANSMITTED\n");

            else
               fprintf('direction type must be UL/DL');
            end            
        end

    end

end
