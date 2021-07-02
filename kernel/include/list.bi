#macro DECLARE_LIST(T)
type LISTNODE(T) field = 1
    PREVNODE as LISTNODE(T) ptr
    NEXTNODE as LISTNODE(T) ptr
    ITEM as T ptr
end type

type LIST(T) field = 1
    FIRSTNODE as LISTNODE(T) ptr
    LASTNODE as LISTNODE(T) ptr
    declare sub AddItem(item as T ptr)
end type

sub LIST(T).AddNode(item as T ptr)
    var node =cptr(LISTNODE(T) ptr, KERNEL_ALLOC(sizeof(LISTNODE(T) ptr)))
    node->NEXTNODE = 0
    node->PREVNODE = this.LASTNODE
    node->ITEM = item
    
    if (this.LASTNODE<>0) then 
        this.LASTNODE->NEXTNODE = node
    else
        this.FIRSTNODE = node
    end if
    
    this.LASTNODE = node
end sub

#endmacro