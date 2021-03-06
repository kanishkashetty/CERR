function planC  = joinH5planC(segMask3M,userOptS,planC)
% function planC  = joinH5planC(segMask3M,userOptS,planC)
%

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

resizeMethod = userOptS.resize.method;
cropS = userOptS.crop; %Added

scanNum = 1;
isUniform = 0;
preserveAspectFlag = 0;

if isfield(userOptS.resize,'preserveAspectRatio') 
    if strcmp(userOptS.resize.preserveAspectRatio,'Yes') 
        preserveAspectFlag = 1; 
    end    
end

cropS.params.saveStrToPlanCFlag=0;
[minr, maxr, minc, maxc, slcV, planC] = getCropLimits(planC,segMask3M,scanNum,cropS);
scanArray3M = planC{indexS.scan}(scanNum).scanArray;
sizV = size(scanArray3M);
maskOut3M = zeros(sizV, 'uint32');
originImageSizV = [sizV(1:2), length(slcV)];

switch lower(resizeMethod)
    
    case 'pad2d'
        limitsM = [minr, maxr, minc, maxc];
        resizeMethod = 'unpad2d';
        originImageSizV = [sizV(1:2), length(slcV)];
        [~, maskOut3M(:,:,slcV)] = ...
            resizeScanAndMask(segMask3M,segMask3M,originImageSizV,resizeMethod,limitsM);
        
    case 'pad3d'
        resizeMethod = 'unpad3d';
        [~, tempMask3M] = ...
            resizeScanAndMask([],segMask3M,sizV,resizeMethod);
        maskOut3M(:,:,slcV) = tempMask3M;
        
    otherwise
        limitsM = [minr, maxr, minc, maxc];
                   
        [~,tempMask3M] = ...
            resizeScanAndMask([],segMask3M,originImageSizV,resizeMethod,limitsM,preserveAspectFlag);
        
        if size(limitsM,1)>1
            %2-D resize methods
            maskOut3M(:,:,slcV) = tempMask3M;
        else
            %3-D resize methods
            maskOut3M(minr:maxr, minc:maxc, slcV) = tempMask3M;
        end
end


for i = 1 : length(userOptS.strNameToLabelMap)
    
    labelVal = userOptS.strNameToLabelMap(i).value;
    maskForStr3M = maskOut3M == labelVal;
    planC = maskToCERRStructure(maskForStr3M, isUniform, scanNum, userOptS.strNameToLabelMap(i).structureName, planC);
    
end