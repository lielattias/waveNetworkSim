function matrix = dispTimeFreqMatrix(GW)
    %% a simple code that enables to see the results nicely
    timefreqMatrix = GW.TimeFreqMatrix;
    matrix = {};
    for i=height(timefreqMatrix):-1:1
        for j=width(timefreqMatrix):-1:1
            node = unique([timefreqMatrix(i,j).Rx, timefreqMatrix(i,j).RxWait, timefreqMatrix(i,j).Tx, timefreqMatrix(i,j).TxRelay]);
            if ~isempty(node)
                matrix(i,j) = {unique([timefreqMatrix(i,j).Rx, timefreqMatrix(i,j).RxWait, timefreqMatrix(i,j).Tx, timefreqMatrix(i,j).TxRelay])};
            else
                matrix(i,j)={0};
            end
        end
    end
    openvar('matrix');
end

