
package mx.managers.systemClasses
{
import flash.events.IEventDispatcher;

[ExcludeClass]

/**
 * @private
 * Simple class to track placeholders for RemotePopups.
 */
public class PlaceholderData extends Object
{
    public function PlaceholderData(id:String, bridge:IEventDispatcher, data:Object)
    {
        this.id = id;
        this.bridge = bridge;
        this.data = data;
    }
    
    public var id:String;               // id of string at this node in the display list
    public var bridge:IEventDispatcher; // bridge to next child application
    public var data:Object;             // either a popup or a bridge to the next application 
}

}