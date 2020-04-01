function inputNames = getInputNames(obj, component)
inputNames = get(component,'InputSignalNames');
conn = get(component,'PortConnectivity');

for iNames=1:length(inputNames)
    if strfind(inputNames{iNames},'<')
        % It is a bus signal
        % We must name it correctly: BusNameSignalName
        busSelector = conn(iNames).SrcBlock;
        
        % conn2 contains connections of the bus selector
        conn2 = get(busSelector,'PortConnectivity');
        for iTmp=1:length(conn2)
            if ~isempty(conn2(iTmp).SrcBlock)
                % This is the source of the bus
                % This is an input signal
                inputBlock = conn2(iTmp).SrcBlock;
                thisName = inputNames{iNames};
                
                outSignalName = get(inputBlock,'OutputSignalNames');
                outSignalName = outSignalName{1};
                if isempty(outSignalName)
                    inputNames{iNames} = ['{' num2str(obj.fpiCounter) '}' get(inputBlock,'Name') thisName(2:end-1) '[t]{/' num2str(obj.fpiCounter) '}'];
                else
                    error('TODO: Implement getInputNames using only FPIstruct instead of monolithic string for entire formula');
                    [outSignalName,~,~,~,~] = obj.getSubStructInfo(outSignalName);
                    startIndex = regexp(outSignalName,'\[t\]');
                    outSignalName = [outSignalName(1:startIndex-1) thisName(2:end-1) outSignalName(startIndex:end)];
                    inputNames{iNames} = outSignalName;
                end
                
                % Rename the signal to [get(inputBlock,'Name')
                % inputNames{iNames}]
                
                obj.fpiCounter = obj.fpiCounter + 1;
            end
        end
    end
end

for n_names = 1:length(inputNames)
    if isempty(inputNames{n_names})
        % The input is empty
        % Do not change it
    elseif isempty(strfind(inputNames{n_names},'sub')) & isempty(strfind(inputNames{n_names},'{')) %#ok<AND2>
        % The input does not contain 'sub' AND does not contain
        % placeholders
        % Add [t] to end and add placeholders
        FPIstruct = struct();
        FPIstruct.prereqSignals = {};
        FPIstruct.prereqFormula = '';
        FPIstruct.formula = [inputNames{n_names} '[t]'];
        
        inputNames{n_names} = ['sub' num2str(obj.subCounter)];
        
        updateStruct = struct();
        updateStruct.startDelay = 0;
        updateStruct.endDelay = 0;
        updateStruct.depth = 0;
        updateStruct.modalDepth = 0;
        updateStruct.FPIstruct = FPIstruct;
        updateStruct.type = 'signal_exp';
        updateStruct.component = component;
        updateStruct.setLogSignalName = 0; % Do not update output name
        
        obj.updateSubStructAndFormulaString(updateStruct)
        
    elseif isempty(strfind(inputNames{n_names},'sub'))
        % The input does not contain 'sub'
        % The signal is something like "{5}SignalName[t]{/5}"
        tmpFormula = regexprep(inputNames{n_names},'{\d*}','');
        tmpFormula = regexprep(tmpFormula,'{/\d*}','');
        FPIstruct = struct();
        FPIstruct.prereqSignals = {};
        FPIstruct.prereqFormula = '';
        FPIstruct.formula = tmpFormula;
        
        inputNames{n_names} = ['sub' num2str(obj.subCounter)];
        
        updateStruct = struct();
        updateStruct.startDelay = 0;
        updateStruct.endDelay = 0;
        updateStruct.depth = 0;
        updateStruct.modalDepth = 0;
        updateStruct.FPIstruct = FPIstruct;
        updateStruct.type = 'signal_exp';
        updateStruct.component = component;
        updateStruct.setLogSignalName = 0; % Do not update output name
        
        obj.updateSubStructAndFormulaString(updateStruct)
    elseif ~isempty(strfind(inputNames{n_names},'<'))
        % The input is e.g. "sub2<Max>"
        % Remove the "<Max>" part to get a signal that we can use eval on.
        lessthan_index = strfind(inputNames{n_names},'<');
        tmp_name = inputNames{n_names};
        inputNames{n_names} = tmp_name(1:lessthan_index-1);
    end
end

end