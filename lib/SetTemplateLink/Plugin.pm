package SetTemplateLink::Plugin;

use strict;
use File::Spec;

sub can_use_set {
    my $app = MT->app;
    return $app->user->is_superuser;
}

sub hdlr_set_linkedfile_templates {
    my $app = shift;
    return $app->permission_denied() unless $app->user->is_superuser;

    my $blog    = $app->blog;
    my $blog_id = $app->blog->id;
    my $plugin  = MT->component('SetTemplateLink');
    my $path =
      $plugin->get_config_value( 'set_template_path', "blog:$blog_id" );
    return $app->error(
        $app->translate(
            "Should be set the linked path in the plugin setting.: [_1]",
            $plugin->errstr
        )
    ) if !$path;

    my $fmgr = $blog->file_mgr;
    unless ( $fmgr->exists($path) ) {
        $fmgr->mkpath($path);
    }

    if ( $fmgr->exists($path) && $fmgr->can_write($path) ) {
        my @temps =
          MT::Template->load( { blog_id => $blog_id }, { sort => 'id' } );
        my $index = 1;
        foreach my $temp (@temps) {
            my $template_id = $temp->id;
            my $basename    = $temp->identifier . '.mtml';
            my $linked_path = File::Spec->catfile( $path, $basename );

            $temp->linked_file($linked_path);
            $temp->save
              or die $app->error(
                $plugin->translate(
                    "Can not save template linked_file.: [_1]",
                    $temp->errstr
                )
              );
            $app->log(
                {
                        message => "Success!! template-id[". $tmp->id. "]"
                      . $temp->linked_file . "[$index]."
                },
            );
            $index++;
        }

        my %param;
        $param{success} = "Success linked_file set $index template file.";
        $app->load_tmpl( 'modal_window.tmpl', \%param );
    }
    else {
        return $app->error(
            $app->translate(
                "Unable to create file in this path: [_1]", $path
            )
        );
    }

}

1;
