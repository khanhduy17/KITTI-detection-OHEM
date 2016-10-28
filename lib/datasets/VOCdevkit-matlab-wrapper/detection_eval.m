function res = detection_eval(path, comp_id, test_set,output_dir,img_list,img_gt)
classes={'car','person','bike', 'truck', 'van', 'tram', 'misc'}
minoverlap=0.5;
class_num=zeros(1,length(classes));
img_list_path= strcat(path,'/',img_list);
img_gt_path= strcat(path,'/',img_gt);
image_list=importdata(img_list_path);


fidin=fopen(img_gt_path);
ind=1;
while ~feof(fidin)
    tline=fgetl(fidin);
    image_list_gt_data{ind}=str2num(tline(29:end));
    ind=ind+1;
end


for i=1:length(image_list)
    image_gt{i}.ids=image_list{i};
    image_gt{i}.total=image_list_gt_data{i}(1);
    ind=2;
    for j=1:length(classes)
        
        %image_list_gt_data{i}(ind)
        
        image_gt{i}.classes{j}=image_list_gt_data{i}(ind);
        if image_gt{i}.classes{j}>0
            
            %image_list_gt_data{i}(ind+1:ind+image_gt{i}.classes{j}*4)
            
            image_gt{i}.bb{j}=reshape(image_list_gt_data{i}(ind+1:ind+image_gt{i}.classes{j}*4),4,image_gt{i}.classes{j})';
        else
            image_gt{i}.bb{j}=[];
        end
        ind=ind+4*image_gt{i}.classes{j}+1;
    end
end
res_path=strcat(path,'/','results/%s_det_',test_set,'_%s.txt');
for i=1:length(classes)
    class_num=0;
    gt(length(image_list))=struct('BB',[]);
    for ii=1:length(image_list)
        if ~isempty(image_gt{ii}.bb{i})
            gt(ii).BB=image_gt{ii}.bb{i};
            class_num=class_num+image_gt{ii}.classes{i};
        end
    end
    [ids,confidence,b1,b2,b3,b4]=textread(sprintf(res_path,comp_id,classes{i}),'%s %f %f %f %f %f');
    BB=[b1 b2 b3 b4];
    [sc,si]=sort(-confidence);
    ids=ids(si);
    BB=BB(si,:);
    nd=length(confidence);
    tp=zeros(nd,1);
    fp=zeros(nd,1);
    
    for j=1:nd
        ovmax=-inf;
        bb_pred=BB(j,:);
        id_index=strmatch(ids{j},image_list,'exact');
        for k=1:size(gt(id_index).BB,1)
            bb_target=gt(id_index).BB(k,:);
            overlap=compute_overlap(bb_pred,bb_target);
            if overlap>ovmax
                ovmax=overlap;
            end
        end
        path=strcat('../../../data/',ids{j});
        %img=imread(path);
        if ~exist(strcat('../../../data/results/',classes{i},'/tp'))
            mkdir(strcat('../../../data/results/',classes{i},'/tp'))
        end
        if ~exist(strcat('../../../data/results/',classes{i},'/fp'))
            mkdir(strcat('../../../data/results/',classes{i},'/fp'))
        end
        write_path1=strcat('../../../data/results/',classes{i},'/tp','/',num2str(j),'.jpg');
        write_path2=strcat('../../../data/results/',classes{i},'/fp','/',num2str(j),'.jpg');
        
       % img_size1 = size(img);
        
        if ovmax>=minoverlap
            tp(j)=1;
            %imwrite( img(fix(bb_pred(2))+1:fix(bb_pred(4)),fix(bb_pred(1))+1:fix(bb_pred(3)), :), write_path1,'jpg');
        else
            fp(j)=1;
           % imwrite( img(fix(bb_pred(2))+1:fix(bb_pred(4)),fix(bb_pred(1))+1:fix(bb_pred(3)), :), write_path2,'jpg');
        end
    end
    fp=cumsum(fp);
    tp=cumsum(tp);
    rec=tp/class_num;
    prec=tp./(fp+tp);
    ap=0;
    for t=0:0.1:1
        p=max(prec(rec>=t));
        if isempty(p)
            p=0;
        end
        ap=ap+p/11;
    end
    if 1
        % plot precision/recall
        plot(rec,prec,'-');
        grid;
        xlabel 'recall'
        ylabel 'precision'
        title(sprintf('class: %s, subset: %s, AP = %.3f',classes{i},test_set,ap));
    end
    ap_auc = xVOCap(rec, prec);
    res(i).recall=rec;
    res(i).prec=prec;
    res(i).ap=ap;
    res(i).ap_auc=ap_auc;
    hold on;
end
fprintf('\n~~~~~~~~~~~~~~~~~~~~\n');
fprintf('Results:\n');
aps = [res(:).ap]';
fprintf('APs:\n')
fprintf('%.1f\n', aps * 100);
fprintf('mAP:')
fprintf('%.1f\n', mean(aps) * 100);
fprintf('~~~~~~~~~~~~~~~~~~~~\n');

