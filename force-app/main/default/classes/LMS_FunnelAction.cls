public class LMS_FunnelAction {
    public String action;
    public String target;
    public String fieldValue;
    
    public static LMS_FunnelAction parse(String definition) {
        List<String> parts = definition.split('\\.');
        
        LMS_FunnelAction fa = new LMS_FunnelAction();
        fa.action = parts[0];
        if(parts.size() > 1) fa.target = parts[1];
        if(parts.size() > 2) fa.fieldValue = parts[2];
        
        return fa;
    }
}