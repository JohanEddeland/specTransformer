classdef specTransformer < handle
    properties(SetAccess = public)
        subSystemLevel = 0; % Integer indicating how many subsystem we have dove into
        logCounter = 1;
        subCounter = 1;
        fpiCounter = 1;
        subStruct = struct();
        formulaString = '';
        skippedString = '';
        paramString = '';
        fileID % This is set by initSTLFile
        fileName % This is set by initSTLFile
        specType = 'safety'; % 'safety' or 'none'
        
        % Character limit for formula. parseOutputToSTL will terminate the 
        % loop if length of string is above this limit
        charLimit = 100000; 
        
        atGotoBlock = 0; % Boolean indicating if we are at a goto-block or not
        gotoBlock % Handle to the goto-block we are at, IF atGotoBlock = 1
        
        muxCounter = 1;
        muxSignals = struct(); % Signals in mux
        
        requirement
        resultsFolder
        model
        
        % safety req is alw_[startTime, endTime](phi)
        startTime
        endTime
        
        compiledSampleTime;
        
        systemHandle = [];
        parentHandle = [];
        timesVisited = [];
        
        tooLongSTLFormula = 0; % This is set to 1 in outportToSTL if the formula is too long
    end
    methods (Access = public)
        
        function obj = specTransformer(model, ...
                requirement, ...
                resultsFolder, ...
                compiledSampleTime)
            
            obj.model = model;
            obj.requirement = requirement;
            obj.resultsFolder = resultsFolder;
            obj.compiledSampleTime = compiledSampleTime;
        end
        
    end
    
    methods (Static)
        [startStrings, endStrings] = getFPIStrings(inputString)
        skipBlock = checkIfBlockShouldBeSkipped(component)
        newFormula = shiftTimeBackwards(formula, timeshift)
        newFormula = shiftTimeForwards(formula, timeshift)
    end
end