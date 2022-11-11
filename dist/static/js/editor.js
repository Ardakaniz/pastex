(function() {
	const flags = {
		original_content: original_content,	
		editor_react_time: 500,
		tab_size: 2,
		font_size: 15,
	}

	let elm = Elm.Editor.init({
		node: document.getElementById('elm'),
		flags: flags['original_content']
	});
	const toElm = elm.ports.toElm.send;

	let editor = ace.edit("editor");
	editor.session.setMode("ace/mode/latex");

	editor.session.setTabSize(flags['tab_size']);
	editor.setFontSize(flags['font_size']);
	editor.setTheme("ace/theme/mono_industrial");
	
	let prevent_editor_change = false;
	let editor_delta_buffer   = [];
	let editor_change_timer   = null;

	let ws = null;

	// Receiving data from Elm
	elm.ports.fromElm.subscribe((data) => {
		console.log(data);
		if (data.type == "ace") {
			prevent_editor_change = true;
			editor.session.setValue(data.content + "\n");
			editor.session.selection.clearSelection();
			prevent_editor_change = false;
		}
		else if (data.type == "ws") {
			if (data.tag == "connect") {
				if (ws !== null) {
					toElm({
						type: "ws",
						tag: "error",
						content: "Websocket connection already established."
					});

					return;
				}

				ws = new WebSocket("ws://" + location.host + "/ws");
				
				ws.addEventListener("message", (e) => {
					const data = e.data;

					if (data.tag == "pdf") {  // Elm cannot handle raw bytes, so we do everything we need in pure JS... :(
						// data.content contains diffed bytes
					} 
					else {
						toElm({
							type: "ws",
							tag: data.tag,
							content: data.content
						});
					}
				})
				
				ws.addEventListener("open", () => {
					toElm({
						type: "ws",
						tag: "connected"
					});
				})

				ws.addEventListener("close", () => {
					toElm({
						type: "ws",
						tag: "disconnected"
					});

					ws = null;
				})
			}
			else if (data.tag == "send") {
				ws.send(data.content);
			}
		} // end "ws"
		else {
			console.log(data.type);
		}
	});

	// Whenever the client change the source code, we notify the diffs to Elm
	editor.session.on('change', (delta) => {
		if (prevent_editor_change)
			return;

		editor_delta_buffer.push(delta);

		if (editor_change_timer === null) {
			editor_change_timer = setTimeout(() => {

				toElm({
					type: "ace",
					content: editor_delta_buffer
				});
				
				editor_delta_buffer = []
				editor_change_timer = null;
			}, flags['editor_react_time'])
		}
	});
})();