property name : "FileSorter"
property version : "3.1.3"

property SortEngine : module
property XList : module 1.6

property _target_container : missing value
property _info_handler : missing value
property _delegate : missing value
property _text_classes : {text, Unicode text, string}

property PointComparator : missing value

on module loaded
	script PointComparator
		property parent : SortEngine's base_comparator()
		property _compare_order : {1, 2}
		
		on set_compare_order(a_list)
			set my _compare_order to a_list
		end set_compare_order
		
		on do(a_first, a_second)
			repeat with ith from 1 to length of my _compare_order
				set an_index to item ith of my _compare_order
				set a_result to continue do(item an_index of a_first, item an_index of a_second)
				if a_result is not 0 then
					exit repeat
				end if
			end repeat
			
			return a_result
		end do
	end script
	set my PointComparator to PointComparator
end module loaded

(*!@title FileSorter Reference
* Version : 3.1.3
* Author : Tetsuro KURITA ((<tkurita@mac.com>))
*)

(*!@group Constructor Methods *)

(*!@abstruct
Make a new FileSorter instance
<!-- end locale -->
@result script object :
<!-- begin locale ja -->FileSorter のインスタンス
<!-- begin locale en -->a new FileSorter instance<!-- end locale -->
*)
on make
	script FileSorter
		property _target_container : missing value
		property _info_handler : missing value
		property _delegate : missing value
	end script
end make

(*!@abstruct
<!-- begin locale ja -->
delegate を設定したインスタンス生成します。
<!-- begin locale en -->
Make a new instance with setting delegate.
<!-- end locale -->
@description
<!-- begin locale ja -->
delegate となる script object は、((<resolve_container>)), ((<target_items_at>)), ((<is_rowwise_for_iconview>)) の何れか、もしくはすべてを実装することによる、FileSorter の動作をカスタマイズできます。
<!-- begin locale en -->
A delegate script object can customize behavior of FileSorter by implementation of handlers ((<resolve_container>)), ((<target_items_at>)) or ((<is_rowwise_for_iconview>)).
<!-- end locale -->
@param a_script : 
<!-- begin locale ja -->delegate となる script object
<!-- begin locale en -->a script object for the delegate
<!-- end locale -->
@result script object : 
<!-- begin locale ja -->FileSorter のインスタンス
<!-- begin locale en -->a new FileSorter instance<!-- end locale -->
*)
on make_with_delegate(a_script)
	set an_instance to make
	an_instance's set_delegate(a_script)
	return an_instance
end make_with_delegate

(*!@group Accessor Methods *)

(*!@abstruct
<!-- begin locale ja -->
delegate を設定します。
<!-- begin locale en -->
set a delegate script into the instance.
<!-- end locale -->
@description
<!-- begin locale ja -->
delegate となる script object は、((<resolve_container>)), ((<target_items_at>)), ((<is_rowwise_for_iconview>)) の何れか、もしくはすべてを実装することによる、FileSorter の動作をカスタマイズできます。
<!-- begin locale en -->
A delegate script object can customize behavior of FileSorter by implementation of handlers ((<resolve_container>)), ((<target_items_at>)) or ((<is_rowwise_for_iconview>)).
<!-- end locale -->
@param a_script (script object) : 
<!-- begin locale ja -->インスタンスの delegate に設定する script object
<!-- begin locale en -->a script object for the delegate
<!-- end locale -->
@result script object : me
*)
on set_delegate(a_script)
	set my _delegate to a_script
	return me
end set_delegate

(*!@abstruct
<!-- begin locale ja -->
設定されている delegate を返します。
<!-- begin locale en -->
Return a delegate script object of the instance.
<!-- end locale -->
@description
<!-- begin locale ja -->
delegate が設定されていないときは、missing value を返します。
<!-- begin locale en -->
If the instance does not have a delegate, missing value is returned.
<!-- end locale -->
@result script object :
<!-- begin locale ja -->インスタンスに delegate として設定されている script object
<!-- begin locale en -->a script object set as a delegate.<!-- end locale -->
*)
on delegate()
	return my _delegate
end delegate

(* handlers for sort_by_view *)
on distill_name(an_item)
	return name of (info for an_item)
end distill_name

on distill_position(an_item)
	tell application "Finder"
		return position of (item (an_item as Unicode text))
	end tell
end distill_position

on distill_moddate(an_item)
	return modification date of (info for an_item)
end distill_moddate

on distill_creationdate(an_item)
	return creation date of (info for an_item)
end distill_creationdate

on distill_size(an_item)
	return size of (info for an_item)
end distill_size

(*
on distill_kind(an_item)
	tell application "Finder"
		return kind of an_item
	end tell
end distill_kind
*)

on distill_version(an_item)
	set theInfo to info for an_item
	return short version of theInfo
end distill_version

on distill_comment(an_item)
	tell application "Finder"
		return comment of an_item
	end tell
end distill_comment

on is_invalid_list(a_list)
	return (a_list is missing value) or ((count a_list) is 0)
end is_invalid_list

on build_sort_table()
	set item_list to missing value
	if my _delegate is not missing value then
		try
			set item_list to my _delegate's target_items_at(my _target_container)
		end try
	else
		set item_list to target_items_at(my _target_container)
	end if
	
	if is_invalid_list(item_list) then
		return item_list
	end if
	
	set keylist to {}
	repeat with ith from 1 to length of item_list
		set end of keylist to my _info_handler(item ith of item_list)
	end repeat
	--log "end build_sort_table"
	return {item_list, keylist}
end build_sort_table

on sort_by(sort_key)
	set source_list to target_items_at(my _target_container)
	
	if is_invalid_list(source_list) then
		return source_list
	end if
	
	tell application "Finder"
		set sorted_list to sort source_list by sort_key
	end tell
	
	if class of item 1 of source_list is in _text_classes then
		script to_hfspath
			on do(an_item, sender)
				tell sender
					set_item_at(an_item as Unicode text, current_index())
				end tell
			end do
		end script
		set fileref_converter to to_hfspath
	else
		script to_alias
			on do(an_item, sender)
				tell sender
					set_item_at(an_item as alias, current_index())
				end tell
			end do
		end script
		set fileref_converter to to_alias
	end if
	
	set sorted_list to XList's make_with(sorted_list)
	sorted_list's enumerate(fileref_converter)
	return sorted_list's list_ref()
end sort_by

(*!@group Instance Methods *)

(*!@abstruct
<!-- begin locale ja -->
Finder の表示に従ってソートされたファイル/フォルダのリストを取得します。
<!-- begin locale en -->
Return a sorted list of files/folders according to the view of Finder.
<!-- end locale -->
@description
<!-- begin locale ja -->
ソートする項目、Finder の表示形式を参照するフォルダは delegate によってカスタマイズできます。
<!-- begin locale en -->
The delegate can customize Items to be sorted and a folder of which view determine the sorting order.
<!-- end locale -->
@result list : 
<!-- begin locale ja -->ソートされたファイル/フォルダのリスト
<!-- begin locale en -->a sorted list of files and folders.<!-- end locale -->
*)
on sorted_items()
	set a_container to resolve_container()
	set a_sorter to make SortEngine
	tell application "Finder"
		if class of a_container is Finder window then
			set a_window to a_container
		else
			set a_window to container window of a_container
		end if
		set a_view to current view of a_window
		
		if a_view is icon view then
			--log "is icon view"
			set view_options to icon view options of a_window
			set an_arrangement to arrangement of view_options
			if an_arrangement is in {not arranged, snap to grid} then
				a_sorter's set_comparator(PointComparator)
				set my _info_handler to distill_position
				
				if my is_rowwise_for_iconview(view_options) then
					PointComparator's set_compare_order({2, 1})
				else
					PointComparator's set_compare_order({1, 2})
				end if
				
				set a_table to my build_sort_table()
				
				if my is_invalid_list(a_table) then
					return a_table
				end if
				set a_list to first item of (a_sorter's sort_table(a_table, -1))
				
			else
				if an_arrangement is arranged by name then
					set a_list to my sort_by(a reference to name)
				else if an_arrangement is arranged by modification date then
					set a_list to my sort_by(a reference to modification date)
				else if an_arrangement is arranged by creation date then
					set a_list to my sort_by(a reference to creation date)
				else if an_arrangement is arranged by size then
					set a_list to my sort_by(a reference to physical size)
				else if an_arrangement is arranged by kind then
					set a_list to my sort_by(a reference to kind)
				else if an_arrangement is arranged by label then
					set a_list to my sort_by(a reference to label index)
				end if
			end if
			
		else if a_view is column view then
			set a_list to my sort_by(a reference to name)
			
		else if a_view is in {list view, flow view} then
			set view_options to list view options of a_window
			set sort_column to sort column of view_options
			set column_name to name of sort_column
			set is_descending to (sort direction of sort_column is reversed)
			
			if column_name is name column then
				set a_list to my sort_by(a reference to name)
			else if column_name is modification date column then
				set a_list to my sort_by(a reference to modification date)
				set is_descending to not is_descending
			else if column_name is creation date column then
				set a_list to my sort_by(a reference to creation date)
				set is_descending to not is_descending
			else if column_name is size column then
				set a_list to my sort_by(a reference to physical size)
			else if column_name is kind column then
				set a_list to my sort_by(a reference to kind)
			else if column_name is label column then
				set a_list to my sort_by(a reference to label index)
			else if column_name is version column then
				set a_list to my sort_by(a reference to version)
			else if column_name is comment column then
				set a_list to my sort_by(a reference to comment)
			end if
			
			if is_descending then
				if not my is_invalid_list(a_list) then
					set a_list to reverse of a_list
				end if
			end if
		else
			error "The FInder Window is Unknown view." number 972
		end if
	end tell
	
	return a_list
end sorted_items

(*!@group Delegate Methods 
<!-- begin locale ja -->
((<make_with_delegate>))、((<set_delegate>)) に以下のいずれかのハンドラを実装したスクリプトを与えることにより、FileSorter の動作をカスタマイズできます。
<!-- begin locale en -->
The behavior of FileSorter can be costomized  by passing a script object which have folloing handlers to  ((<make_with_delegate>)) or ((<set_delegate>)).
<!-- end locale -->
*)

(*!@abstruct
<!-- begin locale ja -->
参照する Finder の表示形式のフォルダを決定します。
<!-- begin locale en -->
Return a folder of which view determine the sorting order.
@description
<!-- begin locale ja -->
デフォルト（このハンドラが実装されていない時）では、Finder の insertion location になります。
<!-- begin locale en -->
The default (i.e. when this handler is omitted.)  location is Finder' insertion location.
<!-- end locale -->
@result alias :
<!-- begin locale ja -->フォルダの alias
<!-- begin locale en -->an alias of a folder<!-- end locale -->
*)
on resolve_container()
	if my _delegate is not missing value then
		try
			set my _target_container to my _delegate's resolve_container()
			return my _target_container
		on error number -1708
		end try
	end if
	
	if my _target_container is not missing value then
		return my _target_container
	end if
	
	--log "obtain insertion location in resolve_container in FileSorter"
	tell application "Finder"
		try
			set a_location to insertion location as alias
		on error -- error when front window is in serarch mode.
			set a_location to first Finder window
		end try
		
		if class of a_location is alias then
			if ((a_location as Unicode text) ends with ":") then
				set is_package to package folder of (info for a_location without size)
				if is_package then
					set a_location to (folder of a_location) as alias
				else
					set a_location to a_location as alias
				end if
			else
				set a_location to (folder of a_location) as alias
			end if
		end if
	end tell
	--log a_location
	set my _target_container to a_location
	return my _target_container
end resolve_container

(*!@abstruct
<!-- begin locale ja -->
ソートするファイル/フォルダを決定します。
<!-- begin locale en -->
Return a list of files and folders to be sort.
<!-- end locale -->
@description
<!-- begin locale ja -->
このハンドラを省略すると、((<resolve_container>)) で返されたフォルダに含まれる項目すべてを取得してソートします。
<!-- begin locale en -->
When this handler is omitted, all items in the folder returned by ((<resolve_container>)) are sorted.
<!-- end locale -->
@param a_location (alias) : 
<!-- begin locale ja -->((<resolve_container>)) の返り値 
<!-- begin locale en -->The returned value form ((<resolve_container>))
<!-- end locale -->
@result list :
<!-- begin locale ja -->ソートするファイル/フォルダのリスト
<!-- begin locale en -->a list of files and folder to be sorted.<!-- end locale -->
*)
on target_items_at(a_location)
	--log "start target_items_at"
	if my _delegate is not missing value then
		try
			return my _delegate's target_items_at(a_location)
		on error number -1708
		end try
	end if
	--log a_location
	if class of a_location is not alias then
		tell application "Finder"
			set a_list to selection as alias list
		end tell
	else
		set a_list to list folder a_location without invisibles
		set container_path to a_location as Unicode text
		repeat with an_item in a_list
			set contents of an_item to (container_path & an_item) as alias
		end repeat
	end if
	
	return a_list
end target_items_at

(*!@abstruct
<!-- begin locale ja -->
アイコン表示の時、行方向でソートするか。
<!-- begin locale en -->
Whether items will be sorted in row wise, when the view is the icon view.
<!-- end locale -->
@description
<!-- begin locale ja -->
((<resolve_container>)) で返されたフォルダが、何からの属性で並び替えが行われていないアイコン表示の場合に呼ばれます。

delegate にこのハンドラが実装されていないときは、label position にしたがって、ソート方向が決定されます。
* bottom の時、行方向のソート
* right の時、列方向のソート
<!-- begin locale en -->
This handler is called, when the view of the folder returned from ((<resolve_container>)) is an icon view not arranged by a property.

If this handler is omitted, the sort direction (row wise or column wise) is determined by the label position property.
* bottom : row wise
* right : column wise
<!-- end locale -->
@param view_options (Finder's Finder window's icon view options) :
<!-- begin locale ja -->
resolve_container で返されたフォルダの icon view options property
<!-- begin locale en -->
The icon view options property of the folder returned from resolve_container.
<!-- end locale -->
@result boolean :
<!-- begin locale ja -->true を返したら行方向にソート
<!-- begin locale en -->sorted in row wise when true is returned.<!-- end locale -->
*)
on is_rowwise_for_iconview(view_options)
	--log "start is_rowwise_for_iconview"
	if my _delegate is not missing value then
		try
			return my _delegate's is_rowwise_for_iconview(view_options)
		on error msg number errno
			if errno is not in {-1700, -1708} then
				error msg number errno
			end if
		end try
	end if
	
	tell application "Finder"
		return label position of view_options is bottom
	end tell
	
end is_rowwise_for_iconview

(* private *)
on debug()
	boot (module loader) for me
	return sorted_items()
end debug

on run --test code
	--return debug()
	try
		show helpbook (path to me) with recovering InfoPlist
	on error msg number errno
		display alert (msg & return & errno)
	end try
end run

